module.exports = {
    entry: "./uploader.js",
    output: {
        path: __dirname,
        filename: "bundle-uploader.js"
    },
    module: {
        loaders: [
            //{ test: /\.css$/, loader: "style!css" }
        ]
    }
};