const { BlobServiceClient } = require("@azure/storage-blob");
module.exports = async function (context, myBlob) {
  const name = context.bindingData.name;
  context.log(`Nuevo blob: ${name} (${myBlob?.length || 0} bytes)`);
  const destConn = process.env.DEST_CONNECTION;
  const destContainer = process.env.DEST_CONTAINER || "processed";
  const destSvc = BlobServiceClient.fromConnectionString(destConn);
  const container = destSvc.getContainerClient(destContainer);
  await container.createIfNotExists();
  const dest = container.getBlockBlobClient(name);
  await dest.upload(myBlob, myBlob.length, { overwrite: true });
  context.log(`Copiado ${name} -> ${destContainer}`);
};
