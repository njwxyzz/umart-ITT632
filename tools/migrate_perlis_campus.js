/**
 * One-time Firestore backfill: campus + campusName for UiTM Perlis.
 *
 * Run from project root (uses firebase-admin from functions/):
 *
 *   cd functions
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"
 *   node ..\tools\migrate_perlis_campus.js --dry-run
 *   node ..\tools\migrate_perlis_campus.js
 *
 * Optional:
 *   --stores     also tag documents in `stores`
 *   --products   also tag documents in `products`
 *   --dry-run    print what would change without writing
 */

const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const CAMPUS_ID = "perlis";
const CAMPUS_NAME = "UiTM Perlis";
const TAG = { campus: CAMPUS_ID, campusName: CAMPUS_NAME };

const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const includeStores = args.includes("--stores");
const includeProducts = args.includes("--products");

function needsCampusTag(data) {
  const campus = (data?.campus ?? "").toString().trim().toLowerCase();
  const campusName = (data?.campusName ?? "").toString().trim();
  return campus !== CAMPUS_ID || campusName !== CAMPUS_NAME;
}

async function migrateCollection(db, collectionName) {
  const snap = await db.collection(collectionName).get();
  let scanned = 0;
  let updated = 0;
  let skipped = 0;

  let batch = db.batch();
  let batchCount = 0;

  async function commitBatch() {
    if (batchCount === 0) return;
    if (!dryRun) await batch.commit();
    batch = db.batch();
    batchCount = 0;
  }

  for (const doc of snap.docs) {
    scanned++;
    const data = doc.data();
    if (!needsCampusTag(data)) {
      skipped++;
      continue;
    }

    updated++;
    console.log(
      `${dryRun ? "[dry-run] " : ""}${collectionName}/${doc.id} → campus=${CAMPUS_ID}, campusName=${CAMPUS_NAME}`,
    );

    if (!dryRun) {
      batch.set(doc.ref, TAG, { merge: true });
      batchCount++;
      if (batchCount >= 400) {
        await commitBatch();
      }
    }
  }

  await commitBatch();

  return { scanned, updated, skipped };
}

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      "Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON path first.",
    );
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
  const db = admin.firestore();

  console.log(`Project: ${admin.app().options.projectId ?? "(from service account)"}`);
  console.log(`Mode: ${dryRun ? "DRY RUN (no writes)" : "LIVE UPDATE"}`);
  console.log("");

  const collections = ["users"];
  if (includeStores) collections.push("stores");
  if (includeProducts) collections.push("products");

  const totals = { scanned: 0, updated: 0, skipped: 0 };

  for (const name of collections) {
    console.log(`--- ${name} ---`);
    const result = await migrateCollection(db, name);
    totals.scanned += result.scanned;
    totals.updated += result.updated;
    totals.skipped += result.skipped;
    console.log(
      `${name}: scanned=${result.scanned}, toUpdate=${result.updated}, alreadyTagged=${result.skipped}\n`,
    );
  }

  console.log("Done.");
  console.log(
    `Total: scanned=${totals.scanned}, ${dryRun ? "wouldUpdate" : "updated"}=${totals.updated}, alreadyTagged=${totals.skipped}`,
  );

  if (dryRun && totals.updated > 0) {
    console.log("\nRe-run without --dry-run to apply changes.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
