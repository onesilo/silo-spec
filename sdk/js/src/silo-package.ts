import JSZip from "jszip";
import type { SiloManifest, SiloContent, SiloPackage } from "./types.js";

/**
 * Opens and parses a .silo zip archive into its constituent parts.
 */
export async function openSiloPackage(
  file: File | Blob
): Promise<SiloPackage> {
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
    for (const [, entry] of Object.entries(refsFolder.files)) {
      if (!entry.dir) {
        refFiles.set(
          entry.name.replace("refs/", ""),
          await entry.async("uint8array")
        );
      }
    }
  }

  return { manifest, content, refFiles };
}

/**
 * Creates a .silo zip archive from a manifest, content, and optional ref files.
 * Returns the archive as a Blob.
 */
export async function createSiloPackage(
  manifest: SiloManifest,
  content: SiloContent,
  refs?: Map<string, Uint8Array>
): Promise<Blob> {
  const zip = new JSZip();

  zip.file("manifest.json", JSON.stringify(manifest, null, 2));
  zip.file("silo.json", JSON.stringify(content, null, 2));

  if (refs && refs.size > 0) {
    const refsFolder = zip.folder("refs")!;
    for (const [path, data] of refs) {
      refsFolder.file(path, data);
    }
  }

  return zip.generateAsync({ type: "blob" });
}
