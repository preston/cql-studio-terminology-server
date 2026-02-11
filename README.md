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
1. Install Docker Desktop, Podman Desktop, or compatible container runtime capable of running "compose" files, and make sure the compute resource settings permit enough:
   * A large amount of RAM headroom, as HAPI FHIR JPA server can allocate a ton of memory, especially during large imports. We recommend 12GB+
   * Enough free disk space. Watch the server logs for disk space errors, as they may not cause the HAPI server to crash.
1. Install `hapi-fhir-cli`. On macOS with brew, `brew install hapi-fhir-cli`
1. Run the creation script with the paths to your terminology .zip files. For example: `./load-terminology-server.sh --snomed data/SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z.zip --loinc data/Loinc_2.81.zip --icd10 data/icd10cm-table\ and\ index-2026.zip`

When the scripts complete, HAPI FHIR will take a while to asyncronously finish processing and indexing content, and could take 10+ minutes. Watch the server logs for progress. In the meantime, the server will remain running and ready to use at http://localhost:8282/fhir . Once your HAPI logs show it has finished processing, we recommend you cleanly stop both HAPI FHIR and Postgres containers and create a snapshot image of the Postgres database container. This will permit easy restoration and sharing with your team. You may alternatively want to alter our compose file to use file system bind mounts for the Postgres container, and use your operating system's normal file management tools.

Please respect the terms and the content you load, particularly with regard to distribution permissions.

# CodeSystem Version

The `hapi-fhir-cli` upload process may not reliably populate `CodeSystem.version` from the source terminology files. If your tooling expects versioned CodeSystem references (e.g. CQL `using` statements with explicit versions), you may need to set these manually after loading.

The following `curl` commands use FHIR PATCH (JSON Patch) to set or update the `version` and `content` (to `"complete"`) on each CodeSystem. They use `add` rather than `replace` because imported CodeSystems may not have these fields at all. Adjust the version values to match your imported content. Replace `2.81`, `20250901`, and `2026` if your terminology files use different releases.

```bash
# SNOMED CT
curl -X PATCH "http://localhost:8282/fhir/CodeSystem/$(curl -s "http://localhost:8282/fhir/CodeSystem?url=http://snomed.info/sct" | jq -r '.entry[0].resource.id')" -H "Content-Type: application/json-patch+json" -d '[{"op": "add", "path": "/version", "value": "20250901"}, {"op": "replace", "path": "/content", "value": "complete"}]'

# LOINC
curl -X PATCH "http://localhost:8282/fhir/CodeSystem/$(curl -s "http://localhost:8282/fhir/CodeSystem?url=http://loinc.org" | jq -r '.entry[0].resource.id')" -H "Content-Type: application/json-patch+json" -d '[{"op": "add", "path": "/version", "value": "2.81"}, {"op": "replace", "path": "/content", "value": "complete"}]'

# ICD-10-CM
curl -X PATCH "http://localhost:8282/fhir/CodeSystem/$(curl -s "http://localhost:8282/fhir/CodeSystem?url=http://hl7.org/fhir/sid/icd-10-cm" | jq -r '.entry[0].resource.id')" -H "Content-Type: application/json-patch+json" -d '[{"op": "add", "path": "/version", "value": "2026"}, {"op": "replace", "path": "/content", "value": "complete"}]'
```

These commands require `jq`. If PATCH is not supported by your HAPI FHIR configuration, use a full `PUT` with the updated resource instead.

# Creating ValueSet Resources

To create ValueSet resources that include all codes from each CodeSystem, use these `curl` commands. Adjust the `version` in each compose include to match your imported content.

```bash
# SNOMED CT ValueSet (all codes)
curl -X PUT "http://localhost:8282/fhir/ValueSet/snomed-ct" -H "Content-Type: application/fhir+json" -d '{"resourceType":"ValueSet","id":"snomed-ct","url":"http://example.org/fhir/ValueSet/snomed-ct","name":"SNOMED CT 20250901","status":"active","compose":{"include":[{"system":"http://snomed.info/sct","version":"20250901"}]}}'

# LOINC ValueSet (all codes)
curl -X PUT "http://localhost:8282/fhir/ValueSet/loinc" -H "Content-Type: application/fhir+json" -d '{"resourceType":"ValueSet","id":"loinc","url":"http://example.org/fhir/ValueSet/loinc","name":"LOINC 2.81","status":"active","compose":{"include":[{"system":"http://loinc.org","version":"2.81"}]}}'

# ICD-10-CM ValueSet (all codes)
curl -X PUT "http://localhost:8282/fhir/ValueSet/icd-10-cm" -H "Content-Type: application/fhir+json" -d '{"resourceType":"ValueSet","id":"icd-10-cm","url":"http://example.org/fhir/ValueSet/icd-10-cm","name":"ICD-10-CM 2026","status":"active","compose":{"include":[{"system":"http://hl7.org/fhir/sid/icd-10-cm","version":"2026"}]}}'
```

# Attribution

Preston Lee