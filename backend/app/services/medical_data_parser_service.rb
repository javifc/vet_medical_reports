class MedicalDataParserService
  def initialize(raw_text)
    @raw_text = raw_text
  end

  def parse
    return {} if @raw_text.blank?

    # Try rule-based parsing first
    structured_data = extract_with_rules

    # TODO: When Ollama is available via Docker, enhance with AI
    # structured_data = enhance_with_ollama(structured_data) if needs_enhancement?

    structured_data.compact
  end

  private

  def extract_with_rules
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

  def extract_pet_name
    patterns = [
      # English
      /Patient(?:\s+Name)?:\s*([^\n]+)/i,
      /Pet(?:\s+Name)?:\s*([^\n]+)/i,
      /Animal(?:\s+Name)?:\s*([^\n]+)/i,
      /Name:\s*([^\n]+)/i,
      # Spanish
      /Nombre(?:\s+del\s+animal)?:\s*([^\n]+)/i,
      /Paciente:\s*([^\n]+)/i,
      /Mascota:\s*([^\n]+)/i,
      # French
      /Nom(?:\s+de\s+l'animal)?:\s*([^\n]+)/i,
      /Patient:\s*([^\n]+)/i,
      # Portuguese
      /Nome(?:\s+do\s+animal)?:\s*([^\n]+)/i,
      # Italian
      /Nome(?:\s+dell'animale)?:\s*([^\n]+)/i,
      /Paziente:\s*([^\n]+)/i
    ]
    extract_first_match(patterns)
  end

  def extract_species
    patterns = [
      # English labels
      /Species:\s*([^\n]+)/i,
      /Animal\s+Type:\s*([^\n]+)/i,
      /Type:\s*([^\n]+)/i,
      # Spanish labels
      /Especie:\s*([^\n]+)/i,
      /Tipo(?:\s+de\s+animal)?:\s*([^\n]+)/i,
      # French labels
      /Espèce:\s*([^\n]+)/i,
      # Portuguese labels
      /Espécie:\s*([^\n]+)/i,
      # Italian labels
      /Specie:\s*([^\n]+)/i,
      # Common species in multiple languages
      /\b(Dog|Cat|Bird|Rabbit|Hamster|Guinea Pig|Ferret|Horse|Cow|Pig)\b/i,
      /\b(Perro|Gato|Pájaro|Conejo|Hámster|Cobaya|Hurón|Caballo|Vaca|Cerdo)\b/i,
      /\b(Chien|Chat|Oiseau|Lapin|Hamster|Cochon d'Inde|Furet|Cheval|Vache|Porc)\b/i,
      /\b(Cão|Gato|Pássaro|Coelho|Hamster|Porquinho da Índia|Furão|Cavalo|Vaca|Porco)\b/i,
      /\b(Cane|Gatto|Uccello|Coniglio|Criceto|Cavia|Furetto|Cavallo|Mucca|Maiale)\b/i
    ]
    extract_first_match(patterns)
  end

  def extract_breed
    patterns = [
      # English
      /Breed:\s*([^\n]+)/i,
      /Race:\s*([^\n]+)/i,
      # Spanish
      /Raza:\s*([^\n]+)/i,
      # French
      /Race:\s*([^\n]+)/i,
      # Portuguese
      /Raça:\s*([^\n]+)/i,
      # Italian
      /Razza:\s*([^\n]+)/i
    ]
    extract_first_match(patterns)
  end

  def extract_age
    patterns = [
      # English
      /Age:\s*([^\n]+)/i,
      /(\d+)\s*(?:years?|months?|weeks?|days?)\s*old/i,
      /(\d+)\s*(?:yr|mo|wk|d)\b/i,
      # Spanish
      /Edad:\s*([^\n]+)/i,
      /(\d+)\s*(?:años?|meses|semanas|días)/i,
      # French
      /Âge:\s*([^\n]+)/i,
      /(\d+)\s*(?:ans?|mois|semaines?|jours?)/i,
      # Portuguese
      /Idade:\s*([^\n]+)/i,
      /(\d+)\s*(?:anos?|meses|semanas|dias)/i,
      # Italian
      /Età:\s*([^\n]+)/i,
      /(\d+)\s*(?:anni|mesi|settimane|giorni)/i
    ]
    extract_first_match(patterns)
  end

  def extract_owner_name
    patterns = [
      # English
      /Owner(?:\s+Name)?:\s*([^\n]+)/i,
      /Client(?:\s+Name)?:\s*([^\n]+)/i,
      /Guardian:\s*([^\n]+)/i,
      # Spanish
      /Propietario:\s*([^\n]+)/i,
      /Dueño:\s*([^\n]+)/i,
      /Cliente:\s*([^\n]+)/i,
      # French
      /Propriétaire:\s*([^\n]+)/i,
      /Client:\s*([^\n]+)/i,
      # Portuguese
      /Proprietário:\s*([^\n]+)/i,
      /Dono:\s*([^\n]+)/i,
      # Italian
      /Proprietario:\s*([^\n]+)/i
    ]
    extract_first_match(patterns)
  end

  def extract_diagnosis
    patterns = [
      # English
      /Diagnosis:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Diagnostic:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Assessment:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Spanish
      /Diagnóstico:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Evaluación:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # French
      /Diagnostic:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Évaluation:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Portuguese
      /Diagnóstico:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Avaliação:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Italian
      /Diagnosi:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Valutazione:\s*([^\n]+(?:\n(?!\w+:).+)*)/i
    ]
    extract_first_match(patterns)
  end

  def extract_treatment
    patterns = [
      # English
      /Treatment:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Plan:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Medication:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Therapy:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Spanish
      /Tratamiento:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Plan:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Medicación:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Terapia:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # French
      /Traitement:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Médicament:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Thérapie:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Portuguese
      /Tratamento:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Medicação:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Terapia:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      # Italian
      /Trattamento:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Farmaci:\s*([^\n]+(?:\n(?!\w+:).+)*)/i,
      /Terapia:\s*([^\n]+(?:\n(?!\w+:).+)*)/i
    ]
    extract_first_match(patterns)
  end

  def extract_veterinarian
    patterns = [
      # English
      /Veterinarian:\s*([^\n]+)/i,
      /Vet:\s*([^\n]+)/i,
      /Doctor:\s*([^\n]+)/i,
      /Dr\.\s+([^\n]+)/i,
      # Spanish
      /Veterinario:\s*([^\n]+)/i,
      /Veterinaria:\s*([^\n]+)/i,
      /Doctor:\s*([^\n]+)/i,
      /Dra?\.\s+([^\n]+)/i,
      # French
      /Vétérinaire:\s*([^\n]+)/i,
      /Docteur:\s*([^\n]+)/i,
      # Portuguese
      /Veterinário:\s*([^\n]+)/i,
      /Veterinária:\s*([^\n]+)/i,
      /Doutor:\s*([^\n]+)/i,
      # Italian
      /Veterinario:\s*([^\n]+)/i,
      /Dottore:\s*([^\n]+)/i
    ]
    extract_first_match(patterns)
  end

  def extract_date
    patterns = [
      # English
      /Date:\s*([^\n]+)/i,
      # Spanish
      /Fecha:\s*([^\n]+)/i,
      # French
      /Date:\s*([^\n]+)/i,
      # Portuguese
      /Data:\s*([^\n]+)/i,
      # Italian
      /Data:\s*([^\n]+)/i,
      # Common date formats
      /(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/,
      /(\d{4}[-\/]\d{1,2}[-\/]\d{1,2})/
    ]
    extract_first_match(patterns)
  end

  def extract_first_match(patterns)
    patterns.each do |pattern|
      match = @raw_text.match(pattern)
      return match.captures.first.strip if match && match.captures.first
    end
    nil
  end
end

