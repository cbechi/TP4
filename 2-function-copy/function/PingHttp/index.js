module.exports = async function (context, req) {
  const name = (req.query.name || (req.body && req.body.name) || "world");
  context.res = { status: 200, body: `pong ${name}` };
};
