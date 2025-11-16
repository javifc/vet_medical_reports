# RuleBasedParserService
# Service responsible for extracting structured medical data using rule-based patterns.
# Supports multiple languages (English, Spanish, French, Portuguese, Italian).
# Tolerant to OCR errors and various document formats.
#
# Usage:
#   parser = RuleBasedParserService.new(raw_text)
#   structured_data = parser.parse
#
class RuleBasedParserService
  def initialize(raw_text)
    @raw_text = normalize(raw_text.to_s)
  end

  def parse
    return {} if @raw_text.strip.empty?

    structured_data = extract_all_fields
    compact_hash(structured_data)
  end

  private

  # Normalización simple para limpiar OCR / PDF -> texto
  def normalize(text)
    s = text.dup
    s = s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    s.gsub!('\r', '\n')
    s.gsub!('\t', ' ')
    # Normalize non-breaking spaces and strange unicode spaces
    s.gsub!("\u00A0", ' ')
    s.gsub!("\u200B", '')
    # collapse multiple spaces and trim
    s.gsub!(/[ ]{2,}/, ' ')
    s.gsub!(/\n{3,}/, "\n\n")
    s.strip
  end

  def compact_hash(h)
    h.reject { |_, v| v.nil? || v.to_s.strip.empty? }
  end

  # --- high level extractor ---
  def extract_all_fields
    {
      pet_name: extract_pet_name,
      species: extract_species,
      breed: extract_breed,
      age: extract_age,
      owner_name: extract_owner_name,
      diagnosis: extract_diagnosis,
      treatment: extract_treatment,
      veterinarian: extract_veterinarian,
      date: extract_date
    }
  end

  # --- helpers for patterns ---
  # Build a tolerant label pattern: accepts optional colon, optional trailing dots, optional OCR noise
  def label_regex(label_variants)
    # variants: array of possible label texts like ['Nombre', 'Nombre del animal']
    escaped = label_variants.map { |v| Regexp.escape(v) }
    # Match at start of line with required colon/dash/dot after label
    /(?:^|\n)\s*(?:#{escaped.join('|')})\s*[:\-\.]\s*/i
  end

  # Capture up to the next label (a line that ends with ':') or a blank line. Uses non-greedy match.
  def capture_block_after(label_variants)
    label = label_regex(label_variants)
    # (?m) multiline, (?U) ungreedy in Ruby -> use non-greedy quantifier + lookahead
    # label is non-capturing group, content is group 1
    /(?:#{label.source})([\s\S]*?)(?=^\s*\w{1,30}\s*[:\-\.]|\z)/im
  end

  def simple_field_after(label_variants)
    label = label_regex(label_variants)
    # grab the rest of the line
    /#{label.source}([^\n\r]+)/i
  end

  # Use safe extraction via String#[regex,1]
  def extract_with(pattern)
    res = @raw_text[pattern, 1]
    return nil if res.nil?
    clean = res.to_s.strip
    clean.empty? ? nil : clean
  end

  # --- field extractors ---
  def extract_pet_name
    # names can include accents, apostrophes, hyphens and multiple words
    patterns = [
      simple_field_after(['Animal Name', 'Patient Name', 'Pet Name', 'Pet', "Patient", 'Paciente', 'Nombre', 'Mascota', "Nombre del animal"]),
      /(?:^|\b)Name[:\-\.]?\s*([A-Za-zÀ-ÖØ-öø-ÿ'\- ]{2,40})/i
    ]

    patterns.each { |p| return normalize_name(extract_with(p)) if extract_with(p) }
    nil
  end

  def extract_species
    patterns = [
      simple_field_after(['Species', 'Animal Type', 'Especie', 'Tipo de animal', 'Espèce', 'Specie', 'Espécie']),
      /\b(Dog|Cat|Perro|Gato|Chien|Chat|Cane|Gatto|Cão)\b/i
    ]
    patterns.each { |p| return extract_with(p) if extract_with(p) }
    nil
  end

  def extract_breed
    patterns = [
      simple_field_after(['Breed', 'Race', 'Raza', 'Razza', 'Raça']),
      /\b(?:Labrador|Retriever|Siamese|Poodle|Bulldog|Beagle|Mixed|Cruce)\b/i,
      # Fallback: any word after 'Raza' or 'Breed'
    ]
    patterns.each { |p| return extract_with(p) if extract_with(p) }
    nil
  end

  def extract_age
    patterns = [
      simple_field_after(['Age', 'Edad', 'Âge', 'Idade', 'Età']),
      /(\d{1,2})\s*(?:years?|años?|yrs?|años|yrs|years|anos|meses|months?|mo)\b/i,
      /(\d)\s*y\b/i
    ]

    patterns.each do |p|
      val = extract_with(p)
      next unless val
      # If it captured only a number group (regex with group), return it; otherwise return normalized line
      return val if val.match(/\d/)
    end
    nil
  end

  def extract_owner_name
    patterns = [
      simple_field_after(["Owner's Name", 'Owner', 'Client Name', 'Propietario', 'Dueño', 'Cliente', 'Proprietario', 'Propriétaire']),
      /(?:Owner|Propietario|Cliente|Guardian|Dueño)[:\-\.]?\s*([A-Za-zÀ-ÖØ-öø-ÿ'\-\. ]{3,60})/i
    ]
    patterns.each { |p| return normalize_person_name(extract_with(p)) if extract_with(p) }
    nil
  end

  def extract_diagnosis
    # try block capture to allow multiple lines until next label
    block_pattern = capture_block_after(['Diagnosis', 'Diagnostic', 'Diagnóstico', 'Diagnosi', 'Diagnóstico', 'Assessment', 'Evaluación', 'Évaluation'])
    val = extract_with(block_pattern)
    return normalize_block(val) if val

    # fallback single-line
    extract_with(simple_field_after(['Diagnosis', 'Diagnóstico', 'Assessment']))
  end

  def extract_treatment
    block_pattern = capture_block_after(['Treatment', 'Plan', 'Tratamiento', 'Medicación', 'Therapy', 'Terapia', 'Tratamento', 'Trattamento'])
    val = extract_with(block_pattern)
    return normalize_block(val) if val

    extract_with(simple_field_after(['Treatment', 'Plan', 'Tratamiento']))
  end

  def extract_veterinarian
    patterns = [
      simple_field_after(['Veterinarian', 'Vet', 'Doctor', 'Dr.', 'Dra.', 'Veterinario', 'Veterinaria', 'Vétérinaire']),
      /(?:Dr|Dra|Doctor|Dottore|Doutor)\.?\s*([A-Za-zÀ-ÖØ-öø-ÿ'\- ]{3,40})/i
    ]
    patterns.each { |p| return extract_with(p) if extract_with(p) }
    nil
  end

  def extract_date
    patterns = [
      simple_field_after(['Date', 'Fecha', 'Data']),
      /(\d{1,2}[\-\/]\d{1,2}[\-\/]\d{2,4})/,
      /(\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2})/
    ]
    patterns.each { |p| return extract_with(p) if extract_with(p) }
    nil
  end

  # --- normalizers ---
  def normalize_name(v)
    return nil if v.nil?
    v.to_s.gsub(/[^A-Za-zÀ-ÖØ-öø-ÿ'\- ]/, '').squeeze(' ').strip
  end

  def normalize_person_name(v)
    return nil if v.nil?
    v.to_s.gsub(/[\t\n\r]+/, ' ').gsub(/\s{2,}/, ' ').strip
  end

  def normalize_block(v)
    return nil if v.nil?
    # remove repeated label at start and trim
    v = v.gsub(/^(?:Diagnosis|Diagnóstico|Tratamiento|Treatment)[:\-\.\s]*/i, '')
    v.strip
  end
end

