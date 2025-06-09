package mnsl;

import haxe.io.Path;

class MNSL {

    /**
     * Parses a MNSL source string and returns a MNSL Context object.
     * @param source The MNSL source string to parse.
     */
    public static function fromSource(source: String, options: MNSLContextOptions): MNSLContext {
        return new MNSLContext(source, options);
    }

    /**
     * Parses a MNSL file and returns a MNSL Context object.
     * @param file The path to the MNSL file to parse.
     */
    public static function fromFile(file: String, options: MNSLContextOptions): MNSLContext {
        #if !MNSL_NO_SYS
        var filePath = sys.FileSystem.absolutePath(file);

        if (!sys.FileSystem.exists(filePath)) {
            throw "sys.io.File not found: " + filePath;
        }

        var fileContent = sys.io.File.getContent(filePath);
        if (fileContent == null) {
            throw "Failed to read file: " + filePath;
        }

        if (options.rootPath == null) {
            options.rootPath = Path.directory(filePath);
        }

        return new MNSLContext(fileContent, options);
        #else
        return new MNSLContext("", options);
        #end
    }

}