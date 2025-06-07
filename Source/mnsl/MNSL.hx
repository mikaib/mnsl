package mnsl;

import sys.io.File;
import sys.FileSystem;
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
        var filePath = FileSystem.absolutePath(file);

        if (!FileSystem.exists(filePath)) {
            throw "File not found: " + filePath;
        }

        var fileContent = File.getContent(filePath);
        if (fileContent == null) {
            throw "Failed to read file: " + filePath;
        }

        if (options.rootPath == null) {
            options.rootPath = Path.directory(filePath);
        }

        return new MNSLContext(fileContent, options);
    }

}