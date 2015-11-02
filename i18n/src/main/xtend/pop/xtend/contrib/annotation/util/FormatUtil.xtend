package pop.xtend.contrib.annotation.util

/**
 * Tools for l10n formatting.
 * 
 */
class FormatUtil {

    private new() {
    }

    /**
     * Converts patterns with 'basic' syntax, see below, to patterns with {@code MessageFormat} syntax. 
     * <p>
     * This 'basic' syntax avoids the nightmare of {@code MessageFormat} escaping rules for single quotes.
     */
    def static fromBasicToClassic(String msg) {
        new FormatConversionEngine().run(msg)
    }

    /**
     * This engine deals with patterns using 'basic' syntax.
     * <p>
     * The syntax is the same as the {@code MessageFormat} one with 2 differences:
     * <li> a standalone single quote is <strong>always</strong> interpreted as a single quote (never needs to be doubled), 
     * <li> left and right braces must be escaped with enclosing single quotes, i.e. "'{'" and "'}'".
     * <p> 
     * Notes.
     * <p>
     * The escaping rules of <a href="http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html">MessageRule</a>
     * are quite confusing as soon as messages with and without parameters are used together, see:
     * <ul>
     * <li><a href="https://bz.apache.org/bugzilla/show_bug.cgi?id=30297">Bug 30297 - fmt strips quotes when using parameter</a> 
     * <li><a href="http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html">MessageFormat javadoc</a> :
     *      <quote>[...]
     *      Warning:
     *      The rules for using quotes within message format patterns unfortunately 
     *      have shown to be somewhat confusing. In particular, it isn't always 
     *      obvious to localizers whether single quotes need to be doubled or not. 
     *      Make sure to inform localizers about the rules, and tell them (for example, 
     *      by using comments in resource bundle source files) which strings will be 
     *      processed by MessageFormat. Note that localizers may need to use single 
     *      quotes in translated strings where the original version doesn't have them. 
     *      </quote>
     * </ul>
     * <p>  
     * To avoid this issue, Oracle chose with its Java Tools to use the escaping rules of 
     *          <a href="https://docs.oracle.com/middleware/1213/adf/api-reference-resource-bundle/oracle/javatools/resourcebundle/NamedMessageFormat.html>
     *              NamedMessageFormat</a>
     * i.e.:
     *     <quote>[...] escaping using single quotes. However, the contents of the text between 
     *        two single quotes is not interpreted only if the first single quote is [immediatly] followed by a left bracket.</br>
     *         Otherwise, a standalone single quote will be interpreted as a single quote
     *      <quote>
     * But those rules are not so easy to master. And they use named parameters, not positioned ones. 
     *  
     */
    private static class FormatConversionEngine {

        static val String SINGLE_QUOTE = "'"
        static val char OPEN_BRACE = '{'
        static val char CLOSE_BRACE = '}'
        static val String CLASSIC_ESCAPED_SINGLE_QUOTE = "''";
        static val String CLASSIC_ESCAPED_OPEN_BRACE = "'{"
        static val String CLASSIC_ESCAPED_CLOSE_BRACE = "}'";
        static val String ESCAPED_OPEN_BRACE = "'\\{'"
        static val String ESCAPED_CLOSE_BRACE = "'}'"
        static val String OPEN_ESCAPING_TAG = "<ESC\\[\\[";
        static val String CLOSE_ESCAPING_TAG = "]]>";

        def run(String msg) {
            if (msg == null) {
                throw new IllegalArgumentException("Message must be specified.")
            }

            if (msg.indexOf(OPEN_BRACE) < 0 && msg.indexOf(CLOSE_BRACE) < 0) {
                return msg
            }

            var r = msg.replaceAll(ESCAPED_OPEN_BRACE, OPEN_ESCAPING_TAG)
            r = r.replaceAll(ESCAPED_CLOSE_BRACE, CLOSE_ESCAPING_TAG)
            r = r.replaceAll(SINGLE_QUOTE, CLASSIC_ESCAPED_SINGLE_QUOTE)
            r = r.replaceAll(CLOSE_ESCAPING_TAG, CLASSIC_ESCAPED_CLOSE_BRACE)
            r = r.replaceAll(OPEN_ESCAPING_TAG, CLASSIC_ESCAPED_OPEN_BRACE)

        }

    }
}