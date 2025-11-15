class MedicalDataParserService
  def initialize(raw_text)
    @raw_text = raw_text
  end

  def parse
    return {} if @raw_text.blank?

    Rails.logger.info("\n" + "=" * 80)
    Rails.logger.info("MEDICAL DATA PARSER - Starting")
    Rails.logger.info("=" * 80)
    
    # Try AI-based structuring with Ollama first
    ollama_available = OllamaStructuringService.ollama_available?
    Rails.logger.info("PARSER - Ollama available: #{ollama_available}")
    
    if ollama_available
      Rails.logger.info("PARSER - Using Ollama for data structuring")
      ollama_data = extract_with_ollama
      Rails.logger.info("PARSER - Ollama extracted #{ollama_data.size} fields: #{ollama_data.keys.inspect}")
      
      # If Ollama extracted enough data, use it; otherwise fallback to rules
      if ollama_data.size >= 3
        Rails.logger.info("PARSER - Ollama data sufficient, returning")
        return ollama_data
      else
        Rails.logger.info("PARSER - Ollama data insufficient (#{ollama_data.size} < 3), falling back to rules")
      end
    else
      Rails.logger.info("PARSER - Ollama not available, using rule-based parsing")
    end

    # Fallback to rule-based parsing
    Rails.logger.info("PARSER - Using rule-based parsing")
    structured_data = extract_with_rules
    Rails.logger.info("PARSER - Rule-based extracted #{structured_data.compact.size} fields: #{structured_data.compact.keys.inspect}")
    Rails.logger.info("=" * 80 + "\n")
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
      # English (with optional colon for OCR errors)
      /'?Animal\s+Name:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,  # More specific for name
      /Patient(?:\s+Name)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      /Pet(?:\s+Name)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      # Spanish
      /Nombre(?:\s+del\s+animal)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      /Paciente:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      /Mascota:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      # French
      /Nom(?:\s+de\s+l'animal)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      /Patient:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      # Portuguese
      /Nome(?:\s+do\s+animal)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      # Italian
      /Nome(?:\s+dell'animale)?:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i,
      /Paziente:?\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i
    ]
    extract_first_match(patterns)
  end

  def extract_species
    patterns = [
      # English labels (with optional colon)
      /Species:?\s*([^\n]+)/i,
      /Animal\s+Type:?\s*([^\n]+)/i,
      # Spanish labels
      /Especie:?\s*([^\n]+)/i,
      /Tipo(?:\s+de\s+animal)?:?\s*([^\n]+)/i,
      # French labels
      /Espèce:?\s*([^\n]+)/i,
      # Portuguese labels
      /Espécie:?\s*([^\n]+)/i,
      # Italian labels
      /Specie:?\s*([^\n]+)/i,
      # Common species in multiple languages
      /\b(Dog|Cat)\b/i,
      /\b(Perro|Gato)\b/i,
      /\b(Chien|Chat)\b/i,
      /\b(Cão|Gato)\b/i,
      /\b(Cane|Gatto)\b/i
    ]
    extract_first_match(patterns)
  end

  def extract_breed
    patterns = [
      # English (with optional colon, handles "Brood" OCR error)
      /Bro+d:?\s*([^\n]+)/i,  # Matches Breed, Brood, etc.
      /Race:?\s*([^\n]+)/i,
      # Spanish
      /Raza:?\s*([^\n]+)/i,
      # French
      /Race:?\s*([^\n]+)/i,
      # Portuguese
      /Raça:?\s*([^\n]+)/i,
      # Italian
      /Razza:?\s*([^\n]+)/i
    ]
    extract_first_match(patterns)
  end

  def extract_age
    patterns = [
      # English (with optional colon, handles "Age/D08" OCR pattern)
      /Age(?:\/D\w+)?:?\s*([^\n]+)/i,
      /(\d+)\s*(?:years?|months?|weeks?|days?)\s*old/i,
      /(\d+)\s*(?:yr|mo|wk|d)\b/i,
      # Spanish
      /Edad:?\s*([^\n]+)/i,
      /(\d+)\s*(?:años?|meses|semanas|días)/i,
      # French
      /Âge:?\s*([^\n]+)/i,
      /(\d+)\s*(?:ans?|mois|semaines?|jours?)/i,
      # Portuguese
      /Idade:?\s*([^\n]+)/i,
      /(\d+)\s*(?:anos?|meses|semanas|dias)/i,
      # Italian
      /Età:?\s*([^\n]+)/i,
      /(\d+)\s*(?:anni|mesi|settimane|giorni)/i
    ]
    extract_first_match(patterns)
  end

  def extract_owner_name
    patterns = [
      # English (with optional colon, handles "'Owner's Name" OCR pattern)
      # Exclude "INFORMATION", "Details", "Field" from matches
      /'?Owner(?:'s)?\s+Name:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,  # First + last name with explicit "Name"
      /Client(?:\s+Name)?:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)(?!\s+(?:INFORMATION|Details|Field))/i,
      /Guardian:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)(?!\s+INFORMATION)/i,
      # Spanish
      /Propietario:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)(?!\s+INFORMACIÓN)/i,
      /Dueño:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      /Cliente:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      # French
      /Propriétaire:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      /Client:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      # Portuguese
      /Proprietário:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      /Dono:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i,
      # Italian
      /Proprietario:?\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/i
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
      if match && match.captures.first
        # Clean up captured text: remove newlines and extra spaces
        cleaned = match.captures.first.strip.split("\n").first&.strip
        return cleaned unless cleaned.blank?
      end
    end
    nil
  end

  def extract_with_ollama
    OllamaStructuringService.new(@raw_text).structure
  rescue => e
    Rails.logger.error("Ollama extraction failed: #{e.message}")
    {}
  end
end

