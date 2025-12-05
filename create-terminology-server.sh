TERMINOLOGY_HOST="localhost"
TERMINOLOGY_PORT=8282

# Optional parameters
SNOMED_ZIP=""
LOINC_ZIP=""
ICD10_ZIP=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --snomed)
            SNOMED_ZIP="$2"
            shift 2
            ;;
        --loinc)
            LOINC_ZIP="$2"
            shift 2
            ;;
        --icd10)
            ICD10_ZIP="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Usage: $0 [--snomed <SNOMED_ZIP>] [--loinc <LOINC_ZIP>] [--icd10 <ICD10_ZIP>]"
            exit 1
            ;;
    esac
done

# Validate that at least one terminology was specified
if [ -z "$SNOMED_ZIP" ] && [ -z "$LOINC_ZIP" ] && [ -z "$ICD10_ZIP" ]; then
    echo "Error: At least one terminology must be specified"
    echo "Usage: $0 [--snomed <SNOMED_ZIP>] [--loinc <LOINC_ZIP>] [--icd10 <ICD10_ZIP>]"
    exit 1
fi

echo "Starting HAPI FHIR JPA terminology server and PostgreSQL database..."
docker compose -f docker-compose-hapi-postgres.yml up --pull always --remove-orphans --detach

echo "Waiting for HAPI FHIR terminology server to be ready..."
while ! curl -s --head --request GET http://$TERMINOLOGY_HOST:$TERMINOLOGY_PORT/fhir/metadata | grep "200"; do sleep 1; done

if [ -n "$LOINC_ZIP" ]; then
    echo "Uploading LOINC terminology..."
    hapi-fhir-cli upload-terminology -v r4 -t http://$TERMINOLOGY_HOST:$TERMINOLOGY_PORT/fhir -s 2GB -u http://loinc.org -d "$LOINC_ZIP" -d data/loincupload.properties
fi

if [ -n "$SNOMED_ZIP" ]; then
    echo "Uploading SNOMED CT terminology..."
    hapi-fhir-cli upload-terminology -v r4 -t http://$TERMINOLOGY_HOST:$TERMINOLOGY_PORT/fhir -s 8GB -u http://snomed.info/sct -d "$SNOMED_ZIP"
fi

if [ -n "$ICD10_ZIP" ]; then
    echo "Uploading ICD-10-CM terminology..."
    hapi-fhir-cli upload-terminology -v r4 -t http://$TERMINOLOGY_HOST:$TERMINOLOGY_PORT/fhir -s 8GB -u http://hl7.org/fhir/sid/icd-10-cm -d "$ICD10_ZIP"
fi

# Does not seem to be necessary, but may be useful in the future.
# echo "Reindexing terminology..."
# hapi-fhir-cli reindex-terminology -v r4 -t http://$TERMINOLOGY_HOST:$TERMINOLOGY_PORT/fhir

echo "Terminology server is ready to use. Please check your HAPI FHIR logs for asynchronous indexing status."