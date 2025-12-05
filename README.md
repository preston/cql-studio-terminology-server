# HAPI FHIR Terminology Server

This project provides a script for creating an instance of the HAPI FHIR JPA server preloaded with several common terminology systems required for practical use. Due to terminology licensing issues surrounding content redistribution, a prebuilt build image cannot be published for anonymous public distribution without the user first acquiring licenses to the terminology systems.

# Creating Your Terminology Server

## System Requirements

HAPI FHIR has a fairly large memory footprint. For these purposes, the Java-based runtime will happily allocate ~10GiB of heap memory, which we have preconfigured as a hard limit.

## Steps
1. Download any combination of the following terminology system .zip files. Do not decompress them.
   * **SNOMED** https://www.nlm.nih.gov/healthit/snomedct/us_edition.html
   * **LOINC** https://loinc.org/download
   * **ICD-10** https://www.cdc.gov/nchs/icd/icd-10-cm/files.html
1. Install Docker Desktop, Podman Desktop, or compatible container runtime capable of running "compose" files, and make sure the compute resource settings permit enough memory headroom.
1. Install `hapi-fhir-cli`. On macOS with brew, `brew install hapi-fhir-cli`
1. Run the creation script with the paths to your terminology .zip files. For example: `./create-terminology-server.sh --snomed data/SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z.zip --loinc data/Loinc_2.81.zip --icd10 data/icd10cm-table\ and\ index-2026.zip`

When complete, HAPI FHIR will take a while to asyncronously finish processing and indexing content but will remain running and ready to use at http://localhost:8282/fhir . Once your HAPI FHIR logs show it has finished processing, we recommend you cleanly stop both HAPI FHIR and Postgres containers and create a snapshot image of the Postgres database container. This will permit easy restoration and sharing with your team. You may alternatively want to alter our compose file to use file system bind mounts for the Postgres container, and use your operating system's normal file management tools.

Please respect the terms and the content you load, particularly with regard to distribution permissions.

# Attribution

Preston Lee