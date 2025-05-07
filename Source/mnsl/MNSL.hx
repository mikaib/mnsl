package mnsl;

import sys.io.File;
import sys.FileSystem;

class MNSL {

    /**
     * Parses a MNSL source string and returns a MNSL Context object.
     * @param source The MNSL source string to parse.
     */
    public static function fromSource(source: String): MNSLContext {
        return new MNSLContext(source);
    }

    /**
     * Parses a MNSL file and returns a MNSL Context object.
     * @param file The path to the MNSL file to parse.
     */
    public static function fromFile(file: String): MNSLContext {
        if (!FileSystem.exists(file)) {
            throw "File not found: " + file;
        }

        var fileContent = File.getContent(file);
        if (fileContent == null) {
            throw "Failed to read file: " + file;
        }

        return new MNSLContext(fileContent);
    }

}