import JSZip from "jszip";
import type { SiloManifest, SiloContent, SiloPackage } from "./types.js";

export async function openSiloPackage(file: File | Blob): Promise<SiloPackage> {
  const zip = await JSZip.loadAsync(file);

  const manifestFile = zip.file("manifest.json");
  if (!manifestFile) throw new Error("Missing manifest.json in .silo package");
  const manifest: SiloManifest = JSON.parse(await manifestFile.async("text"));

  const siloFile = zip.file("silo.json");
  if (!siloFile) throw new Error("Missing silo.json in .silo package");
  const content: SiloContent = JSON.parse(await siloFile.async("text"));

  const refFiles = new Map<string, Uint8Array>();
  const refsFolder = zip.folder("refs");
  if (refsFolder) {
    for (const [path, entry] of Object.entries(refsFolder.files)) {
      if (!entry.dir) {
        refFiles.set(entry.name.replace("refs/", ""), await entry.async("uint8array"));
      }
    }
  }

  return { manifest, content, refFiles };
}
