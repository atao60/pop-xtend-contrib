package pop.xtend.contrib.annotation

import com.google.common.base.CaseFormat
import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.lang.invoke.MethodHandles
import java.text.DateFormat
import java.text.Format
import java.text.MessageFormat
import java.text.NumberFormat
import java.util.AbstractMap
import java.util.Date
import java.util.HashMap
import java.util.HashSet
import java.util.IllformedLocaleException
import java.util.List
import java.util.Locale
import java.util.Map
import java.util.MissingResourceException
import java.util.PropertyResourceBundle
import java.util.ResourceBundle
import org.apache.commons.lang3.text.translate.EntityArrays
import org.apache.commons.lang3.text.translate.LookupTranslator
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.lib.macro.expression.Expression
import org.eclipse.xtend.lib.macro.file.Path
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import pop.xtend.contrib.annotation.util.FormatUtil

import static java.lang.String.format

/** 
 * Makes accessible internationalized messages as a statically typed facade.
 * <p>
 * The facade is generated in front of Java {@link ResourceBundles}. 
 * The annotation will read a given property file: 
 * for each key it adds a static method to the annotated class. 
 * If no file is provided, it will scan the annotated class
 * and use the final fields to create the static methods.  
 * <p>
 * At runtime, the annotated class will lazily fetch the property files for the required language. 
 * If none is available, then it will provide the values of the specified property file to generate the facade.
 * <p>
 * This annotation is quite versatile:
 * <ul>
 * <li>Three formats are available to create the static method names:
 * <ul>
 * <li>Default: the dots are replaced by underscores.
 * <li>Classic: the key is put in capital letters and the dot are replaced as above.
 * <li>Camel: only the first letter of each word is in capital letter and all dots and underscores are removed. 
 * </ul>
 * <li>Two pattern syntaxes are available:  
 * <ul>
 * <li>Classic: the {@link MessageFormat} patterns are used as it is.
 * <li>Basic: it avoids the nightmare of {@code MessageFormat} escaping rules for single quotes.
 * </ul>
 * <li>The static methods can return either the value only or the pair key/value.
 * <li>The static methods can be gathered in a single map with their names as keys.
 * <li>Any property file can be used to provide the default language. No need to set a basename property file. 
 * </ul>
 * <p>
 * The enhanced class is a purely static one. 
 * At runtime, it uses the {@code ResourceBundles} cache management and bundle loading process.
 * 
 * 
 */
@Target(ElementType.TYPE)
@Active(I18nProcessor)
@Documented
annotation I18n {

    enum Escaping {
        classic,
        basic
    }

    enum Provide {
        valueAlone,
        tagAndValue
    }

    enum Style {
        classic,
        camel,
        none
    }

    enum Mapping {
        with,
        none
    }

    /**
     * 
     * The parameters 'folder', 'basename' and 'language' specify the property file whose key/value pairs
     * will be used to generate the static methods:
     * <ul>
     * <li>Search all the property files with the given basename, inside the whole set of source folders
     * and their trees of sub folders. 
     * <li>If a folder is given, it constrains the searching under each source folder to this folder
     * and its tree of sub folders.
     * <li>If a language is given, it constrains the searching to the set of property files with this language.
     * <li>If no basename is given, the annotated class' simple name is used as basename.
     * <li>If no property files is found, use the final fields of the annotated class as properties.
     * <ul>
     * At runtime, the specified language is used as the default language by the enhanced class.
     */
    String folder = ""

    String basename = ""

    String language = ""

    /**
     * Two escaping rules are available:
     * <ul>
     * <li>'classic': the escaping rules are the same as the ones of {@code MessageFormat}
     * <li>'basic': the escaping rules are very close of the {@code MessageFormat} ones but:
     * <ul>
     * <li>a standalone single quote is <strong>always</strong> interpreted as a single quote, 
     * <li> eft and right braces must be escaped with enclosing single quotes, i.e. "'{'" and "'}'".
     * </ul>
     * <li>if none or any other value, then 'basic' rule will be used.
     * </ul>
     */
    Escaping escaping = Escaping.basic

    /**
     * Specify if the static functions must provide either the property value alone or a pair tag + value.
     */
    Provide provide = Provide.tagAndValue

    /**
     * Specify if the name of all the generated static methods should have the same style, either classic 
     * or camel, or if the key is taken as it is.
     */
    Style style = Style.none

    /**
     * Specify if a map of all the static methods will be provided.
     */
    Mapping mapping = Mapping.none

    /**
     * Can be used to find a property file outside the source folders of the project.
     * 
     * To the time being, it's required as a workaround about:
     *     Bug 476609 - projectSourceFolders doesn't catch the resources folders when used with Maven outside Eclipse
     *     https://bugs.eclipse.org/bugs/show_bug.cgi?id=476609
     */
    String[] sources = #[];
}

class I18nProcessor extends AbstractClassProcessor {

    public static val DEFAULT_LANGUAGE = Locale.ROOT
    public static val DEFAULT_ESCAPING_RULE = I18n.Escaping.basic
    public static val DEFAULT_PROVIDER_RULE = I18n.Provide.tagAndValue
    public static val DEFAULT_METHOD_NAME_STYLE = I18n.Style.none
    public static val DEFAULT_METHOD_MAPPING = I18n.Mapping.none
    public static val String[] DEFAULT_EXTRA_SOURCES = #[]

    override doTransform(MutableClassDeclaration cls, TransformationContext context) {
        extension val util = new Util(cls, context)

        addLogger
        addDefaultLocalField
        addAvailableResourceBundleListField
        val basename = addAllMessageGetters
        addMessageMapping
        addResourceBundleGetter(basename)
        removeAllMessageFields

    }

    private static class Util {

        static val I18N_FOLDER_PATH = "folder"
        static val I18N_BASE_NAME = "basename"
        static val I18N_LANGUAGE = "language"
        static val I18N_ESCAPING_RULES = "escaping"
        static val I18N_PROVIDE = "provide"
        static val I18N_STYLE = "style"
        static val I18N_EXTRA_SOURCES = "sources"
        static val I18N_MAPPING = "mapping"

        static val STRING_DELIMITER = "\""
        static val TEMPLATE_DELIMITER = "'''"
        static val PROPERTIES_FILE_EXTENSION = "properties"
        
        static val Logger LOG = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass())
        
        /*
         * Don't use org.apache.commons.lang3.StringEscapeUtils.escapeJava or ESCAPE_JAVA 
         * as they also translate any non ASCII character, even qualified ISO-8859-1 ones. 
         * 
         */
        static val ESCAPE_JAVA = 
          new LookupTranslator(#[
              #["\"", "\\\""], 
              #["\\", "\\\\"]
          ])
          .with(new LookupTranslator(EntityArrays.JAVA_CTRL_CHARS_ESCAPE))

        val extension TransformationContext context
        val AnnotationReference i18n
        val MutableClassDeclaration annotatedClass
        val Function1<FieldDeclaration, Boolean> messageFieldFilter

        var Locale localeCache = null
        var I18n.Escaping formattingRuleCache = null
        var I18n.Provide providerFormatCache = null
        var I18n.Style methodNameStyleCache = null
        var I18n.Mapping methodMappingCache = null
        var List<Path> sourceListCache = null
        var Map<String, String> messages = null

        new(MutableClassDeclaration annotatedClass, TransformationContext context) {
            this.annotatedClass = annotatedClass
            this.i18n = annotatedClass.getAnnotation(I18n, context)
            this.context = context
            messageFieldFilter = [FieldDeclaration it|final && ! static && thePrimaryGeneratedJavaElement]
        }

        def addLogger() {
            annotatedClass.addField("LOGGER") [
                static = true
                final = true
                type = Logger.newTypeReference
                initializer = '''«LoggerFactory».getLogger(«annotatedClass».class)'''
                primarySourceElement = annotatedClass
            ]
        }

        def addDefaultLocalField() {
            annotatedClass.addField("DEFAULT_LOCALE") [
                static = true
                final = true
                type = Locale.newTypeReference
                initializer = '''
                    «IF defaultLocale == Locale.ROOT»
                        Locale.ROOT
                    «ELSE»
                        new «Locale»("«defaultLocale»")
                    «ENDIF»
                '''
                primarySourceElement = annotatedClass
            ]
        }

        def private Locale getDefaultLocale() {
           propertyFileLanguage
        }

        def addAvailableResourceBundleListField() {
            annotatedClass.addField("RESOURCE_BUNDLE_AVAILABILITY") [
                static = true
                final = true
                type = Map.newTypeReference(Locale.newTypeReference, Locale.newTypeReference)
                initializer = '''«CollectionLiterals».newHashMap()'''
                primarySourceElement = annotatedClass
            ]
        }

        /*
         * Use:
         * <ul>
         * <li>the ResourceBundle cache management for the available property files
         * <li>a map of redirections for any required locale without associated property file
         * </ul>
         * 
         */
        def addResourceBundleGetter(String basename) {
            annotatedClass.addMethod("getResourceBundle") [
                visibility = Visibility.PRIVATE
                static = true
                addParameter("locale", Locale.newTypeReference)
                returnType = ResourceBundle.newTypeReference
                body = '''
                    if(! RESOURCE_BUNDLE_AVAILABILITY.containsKey(locale)) {
                        try {
                            ResourceBundle.getBundle("«basename»", locale);
                            RESOURCE_BUNDLE_AVAILABILITY.put(locale, locale);
                        } catch(«MissingResourceException» mre) {
                            if(locale == null || locale == «Locale».ROOT) {
                                LOGGER.warn("No locale specified: '{}' used by default.", DEFAULT_LOCALE);
                            } else {
                                LOGGER.warn("No resource bundle '{}' available for locale '{}': '{}' used by default.", 
                                    "«basename»", locale, DEFAULT_LOCALE);
                            }
                            RESOURCE_BUNDLE_AVAILABILITY.put(locale, DEFAULT_LOCALE);
                        }
                    }
                    «Locale» fl = RESOURCE_BUNDLE_AVAILABILITY.get(locale);
                    return ResourceBundle.getBundle("«basename»", fl);
                '''
                primarySourceElement = annotatedClass
            ]
        }

        def private getMessageReadyForMessageFormat(String msg) {
            var r = FormatUtil.fromBasicToClassic(msg)
            return r
        }
        
        def addMessageMapping() {
            if (!isWithMethodMap) {
                return
            }
            if (messages === null) {
                annotatedClass.addError("Illegal state: message map not initialized.")
            }
            annotatedClass.addField("MESSAGE_MAP") [
                static = true
                final = true
                type = Map.newTypeReference(Locale.newTypeReference,  Map.newTypeReference(string, string))
                initializer = '''
                    new «HashMap»<>()
                '''
                primarySourceElement = it
            ]
            annotatedClass.addMethod("getMessages") [
                visibility = Visibility.PUBLIC
                static = true
                addParameter("locale", Locale.newTypeReference)
                returnType = Map.newTypeReference(string, string)
                body = '''
                    if (! MESSAGE_MAP.containsKey(locale)) {
                        «Map»<String, String> tm = «CollectionLiterals».newImmutableMap( 
                        «FOR m: messages.entrySet SEPARATOR ','»
                        new «Pair»<String, String>("«m.value»", «m.value»(locale))
                        «ENDFOR» 
                        );
                        MESSAGE_MAP.put(locale, tm);
                    }
                    return MESSAGE_MAP.get(locale);
                '''
                primarySourceElement = it
            ]
            
        }

        def addAllMessageGetters() {
            val props = annotatedClass.properties
            val basename = props.key
            val properties = props.value
            messages = newHashMap
            properties.forEach[p|annotatedClass.addMessageGetter(p)]
            basename
        }

        def removeAllMessageFields() {
            annotatedClass.declaredFields.filter(messageFieldFilter).forEach[remove]
        }
        
        def isUsingBasicRules() {
            propertyFileEscapingRule === I18n.Escaping.basic
        }
        
        def private void addMessageGetter(MutableClassDeclaration it, Pair<String, String> property) {
            var String methodName = null;
            try {

                val key = property.key
                methodName = getMethodeNameFromKey(key)
                val msg_ = property.value 
                val msg = if (!isUsingBasicRules) msg_ else msg_.getMessageReadyForMessageFormat

                addMethod(methodName) [
                    val msgFormat = try {
                        new MessageFormat(msg)
                    } catch (IllegalArgumentException e) {
                        addError("Invalid format: " + e.message)
                        new MessageFormat("")
                    }
                    val Format[] formats = msgFormat.formatsByArgumentIndex
                    if (msgFormat.formats.length != formats.length) {
                        addWarning('Unused placeholders: ' + msg)
                    }

                    addParameter("locale", Locale.newTypeReference)
                    formats.forEach [ Format format, idx |
                        addParameter("arg" + idx, switch format {
                            NumberFormat: primitiveInt // FIXME: integer only?
                            DateFormat: Date.newTypeReference()
                            default: string // MessageFormat?
                        })
                    ]
                    varArgs = false
                    returnType = if(providerFormat === I18n.Provide.tagAndValue) Map.Entry.
                        newTypeReference(string, string) else string
                    docComment = msg
                    static = true

                    val escapedJavaMsg = ESCAPE_JAVA.translate(msg)
                    body = '''
                        «String» msg = null;
                        try {
                            msg = getResourceBundle(locale).getString("«key»");
                        } catch («MissingResourceException» e) {
                            msg = "«escapedJavaMsg»";
                            LOGGER.warn("No value available for '«key»', use by default: '{}'", msg);
                        }
                        «IF formats.length > 0»
                            «IF isUsingBasicRules»
                                msg = «FormatUtil».fromBasicToClassic(msg);
                            «ENDIF»
                            msg = «MessageFormat».format(msg, «parameters.map[simpleName].join(", ")»);
                        «ENDIF»
                        «IF providerFormat === I18n.Provide.tagAndValue»
                            return new «AbstractMap.SimpleEntry»("«key»", msg);
                        «ELSE»
                            return msg;
                        «ENDIF»
                    '''
                    primarySourceElement = it
                ]
                messages.put(key, methodName)
                return

            } catch (IllegalArgumentException e) {
                addWarning('''I18n.addMessageGetter, method name («methodName») with «e»''')
            }
        }
        
        def private getProperties(ClassDeclaration it) {
            val folder = propertyFileFolder
            val basename = propertyFileBasename
            val language = propertyFileLanguage
            LOG.debug(
                "@I18n.getProperties(ClassDeclaration) [language={}«language», basename={}«basename», folder={}]", 
                language, basename, folder)

            val ef = getPropertyFile(folder, basename, language)

            if (ef === null) {
                addError('''
                    Use the fields of the annotated class '«it.simpleName»':
                    «IF basename.empty»
                        no basename provided. 
                    «ELSE»
                        unable to find any property file «IF !folder.empty»under folder '«folder»' «ENDIF»with basename '«basename»'.
                        Note. Any file more specific than «basename».properties will be ignored: 
                              check if exists «basename».properties or a less specific file.
                    «ENDIF»
                ''')
                return null -> propertiesFromClass
            }
            val file = ef.value
            ef.key -> file.propertiesFromFile
        }

        def private getPropertyFile(ClassDeclaration it, String folder, String name, Locale language) {

            val basename = getBaseNameIfEmptyFromClass(name)
            val localizedbasename = basename.getLocalizedBasename(language)
            val ef = findPropertyFiles(folder, localizedbasename)
            if (ef.empty) {
                return null
            }
            val file = ef.get(0).value.get(0)
            val files = ef.map[value].flatten
            if (files.length > 1) {
                addWarning('''
                    File used to fill the annotated class «it.simpleName»: «file.toString».
                    The full list of candidates is: «files». 
                ''')
            }
            val source = ef.get(0).key
            val Path parent = file.parent
            val fullbasename = source.relativize(parent).append(basename).toString.replaceAll("^/", "").replace("/", ".")
            fullbasename -> file

        }

        /*
         * Return a map of source folders with properties files for which there is at least one such file.
         * If a folder is provided, the search is done only under it as sub-folder of each source folder.  
         */
        def private findPropertyFiles(ClassDeclaration it, String folder, String basename) {
            val cls = it
            val sourcefolders = new HashSet(compilationUnit.filePath.projectSourceFolders) => [
                // FIXME: workaround for the bug https://bugs.eclipse.org/bugs/show_bug.cgi?id=476609.
                // To be removed as soon as the bug is fixed.
                addAll(cls.compilationUnit.filePath.projectFolder.getAdditionalSourceFolders)
// test:start
                LOG.debug("@I18n.findPropertyFiles(class, folder, basename): if needed, {} "
                    + "will be searched in source folders: \n- {}", cls.compilationUnit.filePath, it.join("\n- ")
                )      
// test:end          
            ]
            addWarning('''
            
            The full list of source folders: 
                «FOR f : sourcefolders»
                ---> «f»
                «ENDFOR»
            ''')
//            val result = sourcefolders
//                .map[
//                    LOG.debug("@I18n.findPropertyFiles(class, folder, basename), source folder: {}", it)
//                    it -> append(folder).findPropertyFilesWithBasename(basename, cls)
//                ]
//                .filter[!value.empty]
            val result = <Pair<Path, Iterable<? extends Path>>>newArrayList => [
                for(sfp: sourcefolders) {
                    LOG.debug("@I18n.findPropertyFiles(class, folder, basename), source folder: {}", sfp)
                    val filelist = sfp.append(folder).findPropertyFilesWithBasename(basename, cls)
                    if (!filelist.empty) {
                        add(sfp -> filelist)
                    }
                }
            ]
            LOG.debug("@I18n.findPropertyFiles(class, folder, basename), path map: {}", result)
            result
        }

        /*
         * Only properties files as much specific as the one specified by basename are looked for.
         */
        def private Iterable<? extends Path> findPropertyFilesWithBasename(Path it, String basename,
            ClassDeclaration cls) {
            val paths = <Path>newLinkedHashSet
            if (! isFolder) {
                return paths
            }
            LOG.debug("@I18n.findPropertyFilesWithBasename(path, basename, class), basename: {}", basename)
            val rootname = basename

            paths += children
                .filter[fileExtension == PROPERTIES_FILE_EXTENSION]
                .filter [
                    LOG.debug("@I18n.findPropertyFilesWithBasename(path, basename, class), path: {}", toString)
                    val baseLastSegment = lastSegment.substring(0, lastSegment.lastIndexOf("." + PROPERTIES_FILE_EXTENSION))
                    (baseLastSegment.startsWith(rootname) &&
                        (baseLastSegment == basename || baseLastSegment.length < basename.length))
                ]
            paths += children.filter[isFolder].map[findPropertyFilesWithBasename(basename, cls)].flatten
            LOG.debug("@I18n.findPropertyFilesWithBasename(path, basename, class), paths: {}", paths)
            paths
        }

        def static private getAnnotation(
            ClassDeclaration it,
            Class<?> annotationType,
            extension TransformationContext context
        ) {
            findAnnotation(annotationType.newTypeReference.type)
        }

        def private getAnnotationPropertyValue(String tag) {
            i18n.getValue(tag) as String
        }

        def private getPropertyFileFolder() {
            (getAnnotationPropertyValue(I18N_FOLDER_PATH) ?: "").trim
        }

        def private getPropertyFileBasename() {
            (getAnnotationPropertyValue(I18N_BASE_NAME) ?: "").trim
        }

        def private Locale getPropertyFileLanguage() {
            if (localeCache === null) {
                val l = (getAnnotationPropertyValue(I18N_LANGUAGE) ?: "").trim
                localeCache = if (l.empty) {
                    DEFAULT_LANGUAGE
                } else
                    try {
                        new Locale.Builder().setLanguageTag(l).build
                    } catch (IllformedLocaleException e) {
                        i18n.addError('''The provided language code '«l»' is ill formed: 
                        default language will be used (see root basename property file or annotated class).''')
                        DEFAULT_LANGUAGE
                    }
            }
            localeCache
        }

        def private getPropertyFileEscapingRule() {
            if (formattingRuleCache === null) {
                formattingRuleCache = try {
                    I18n.Escaping.valueOf(i18n.getEnumValue(I18N_ESCAPING_RULES).simpleName)
                } catch (IllegalArgumentException e) {
                    DEFAULT_ESCAPING_RULE
                } catch (NullPointerException e) {
                    DEFAULT_ESCAPING_RULE
                }
            }
            formattingRuleCache
        }

        def private getProviderFormat() {
            if (providerFormatCache === null) {
                providerFormatCache = try {
                    I18n.Provide.valueOf(i18n.getEnumValue(I18N_PROVIDE).simpleName)
                } catch (IllegalArgumentException e) {
                    DEFAULT_PROVIDER_RULE
                } catch (NullPointerException e) {
                    DEFAULT_PROVIDER_RULE
                }
            }
            providerFormatCache
        }

        def private getMethodNameStyle() {
            if (methodNameStyleCache === null) {
                methodNameStyleCache = try {
                    I18n.Style.valueOf(i18n.getEnumValue(I18N_STYLE).simpleName)
                } catch (IllegalArgumentException e) {
                    DEFAULT_METHOD_NAME_STYLE
                } catch (NullPointerException e) {
                    DEFAULT_METHOD_NAME_STYLE
                }
            }
            methodNameStyleCache
        }
        
        def private isWithMethodMap() {
            methodMapping === I18n.Mapping.with
        }

        def private getMethodMapping() {
            if (methodMappingCache === null) {
                methodMappingCache = try {
                    I18n.Mapping.valueOf(i18n.getEnumValue(I18N_MAPPING).simpleName)
                } catch (IllegalArgumentException e) {
                    DEFAULT_METHOD_MAPPING
                } catch (NullPointerException e) {
                    DEFAULT_METHOD_MAPPING
                }
            }
            methodMappingCache
        }

        def private getAdditionalSourceFolders(Path project) {
            if (sourceListCache === null) {
                val extrasources = try {
                    i18n.getStringArrayValue(I18N_EXTRA_SOURCES)
                } catch (IllegalArgumentException e) {
                    DEFAULT_EXTRA_SOURCES
                } catch (NullPointerException e) {
                    DEFAULT_EXTRA_SOURCES
                }
                sourceListCache = extrasources.map[project.append(it)]
            }
            sourceListCache
        }

        def private getPropertiesFromFile(Path propertyFile) {
            val is = propertyFile.contentsAsStream
            val bundle = new PropertyResourceBundle(is)
            bundle.keySet.map[it -> bundle.getString(it)]
        }

        def private getPropertiesFromClass(ClassDeclaration it) {
            declaredFields.filter(messageFieldFilter).map[simpleName -> initializerAsString]
        }

        def private getInitializerAsString(FieldDeclaration it) {
            val Expression initializer = getInitializer
            if (initializer === null) {
                addWarning("No initializer is provided: empty string will be used")
                return ""
            }
            val value = initializer.toString.replaceAll("(\\r|\\n)", "")
            if (value.startsWith(STRING_DELIMITER)) {
                return value.substring(STRING_DELIMITER.length, value.length - STRING_DELIMITER.length)
            }
            if (value.startsWith(TEMPLATE_DELIMITER)) {
                val v = value.substring(TEMPLATE_DELIMITER.length, value.length - TEMPLATE_DELIMITER.length)
                addWarning(
                    format("Template expression '%s' is treated as simple string. No interpolation will be done.", v))
                return v
            }
            addError(
                format("The initializer '%s' is neither a string nor a template expression. It will be used as it is.",
                    value))
            value
        }

        def private getMethodeNameFromKey(String key) {
            var k = key.replaceAll("\\.", "_")
            switch methodNameStyle {
                case I18n.Style.classic: {
                    CaseFormat.LOWER_CAMEL.to(CaseFormat.UPPER_UNDERSCORE, k)
                }
                case I18n.Style.camel: {
                    CaseFormat.UPPER_UNDERSCORE.to(CaseFormat.LOWER_CAMEL, k)
                }
                default: {
                    k
                }
            }
        }

        def static private getBaseNameIfEmptyFromClass(ClassDeclaration it, String basename) {
            if(basename.empty) simpleName else basename
        }

        def static private getLocalizedBasename(String basename, Locale language) {
            basename + if(language == Locale.ROOT) "" else ("_" + language)
        }

    }

}

