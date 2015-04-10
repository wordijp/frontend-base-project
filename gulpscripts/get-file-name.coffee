module.exports = (path) -> path.replace(/\\/g, '/').split('/')[-1..-1][0]
