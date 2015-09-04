package pop.xtend.contrib.annotation

import com.google.common.base.CaseFormat
import java.io.StringReader
import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.text.DateFormat
import java.text.Format
import java.text.MessageFormat
import java.text.NumberFormat
import java.util.AbstractMap
import java.util.Date
import java.util.IllformedLocaleException
import java.util.List
import java.util.Locale
import java.util.Map
import java.util.MissingResourceException
import java.util.PropertyResourceBundle
import java.util.ResourceBundle
import org.apache.commons.lang3.StringEscapeUtils
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
import static pop.xtend.contrib.annotation.I18nProcessor.*
import java.util.HashSet

/** 
 * This annotation reads a property file and for each pair of key/value 
 * adds a static method to the annotated class. These methods can return
 * either only the value or the pair key/value
 * 
 * TODO
 * - find why compilationUnit.filePath.projectSourceFolders returns only the sources
 *   folders when used outside of Eclipse
 * - add a parameter "style" for the name of the static methods, with 3 options : 
 *   - classic: all capitals with underscore
 *   - camel: camel style
 *   - none: use the key as it is
 * 
 * 
 */
@Target(ElementType.TYPE)
@Active(I18nProcessor)
@Documented
annotation I18n {
    
    enum Escaping {classic, basic}
    enum Provide {valueAlone, tagAndValue}
    enum Style {classic, camel, none}
    
    /**
     * Search all the property files with the given basename, inside the whole set of source folders
     * and their trees of sub folders. 
     * 
     * If a folder is given, it constrains the searching under each source folder to this folder
     * and its tree of sub folders.
     * 
     * If a language is given, it constrains the searching to the set of property files with this language.
     * 
     * If no basename is given, the annotated class' simple name is used as basename.
     * 
     * If no property files is found, use the final fields of the annotated class as properties.
     * 
     */
    String folder = ""
    
    String basename =  ""
    
    String language = ""
 
    /**
     * Two escaping rules are available:
     * <ul>
     * <li>'classic': the escaping rules are the same as the ones of 
     *     <a href="http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html">MessageRule</a>
     * <li>'basic': the escaping rules are very close of the MessageFormat ones with 2 changes:
     * <ul>
     * <li> a standalone single quote is interpreted as a single quote, 
     * <li> left and right braces must be escaped with enclosing single quotes, i.e. "'{'" and "'}'".
     * </ul>
     * <li>if any other value, then 'basic' rule will be used.
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
     
    /*
     * A workaround about:
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
    public static val String[] DEFAULT_EXTRA_SOURCES = #[]
    
    override doTransform(MutableClassDeclaration it, TransformationContext context) {
        extension val util = new Util(context)
        
        addLogger
        addDefaultLocalField
        addAvailableResourceBundleListField
        val basename = addAllMessageGetters
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
        static val I18N_EXTRA_SOURCES= "sources"
    
        static val STRING_DELIMITER = "\""
        static val TEMPLATE_DELIMITER = "'''"
        static val LOCALE_SEP = "_"
    
        val extension TransformationContext context
        val Function1<FieldDeclaration, Boolean> messageFieldFilter
        
        var Locale localeCache = null
        var I18n.Escaping formattingRuleCache = null
        var I18n.Provide providerFormatCache = null
        var I18n.Style methodNameStyleCache = null
        var List<Path> sourceListCache = null
                
        new(TransformationContext context) {
            this.context = context
            messageFieldFilter = [FieldDeclaration it | final && ! static && thePrimaryGeneratedJavaElement]
        }
        
        def private addLogger(MutableClassDeclaration annotatedClass) {
            annotatedClass.addField("LOGGER") [
                static = true
                final = true
                type = Logger.newTypeReference
                initializer = '''«LoggerFactory».getLogger(«annotatedClass».class)'''
                primarySourceElement = annotatedClass
            ]
        }  
        
        def private addDefaultLocalField(MutableClassDeclaration annotatedClass) {
            annotatedClass.addField("DEFAULT_LOCALE") [
                static = true
                final = true
                type = Locale.newTypeReference
                initializer = '''
                    «IF annotatedClass.defaultLocale == Locale.ROOT»
                        Locale.ROOT
                    «ELSE»
                        new «Locale»("«annotatedClass.defaultLocale»")
                    «ENDIF»
                    '''
                primarySourceElement = annotatedClass
            ]
        }

        def private Locale getDefaultLocale(ClassDeclaration it) {
            val ia = getAnnotation(I18n, context)
            ia.propertyFileLanguage
        }
 
        
        def private addAvailableResourceBundleListField(MutableClassDeclaration annotatedClass) {
            annotatedClass.addField("RESOURCE_BUNDLE_AVAILABILITY") [
                static = true
                final = true
                type = Map.newTypeReference(Locale.newTypeReference, Locale.newTypeReference)
                initializer = '''«CollectionLiterals».newHashMap()'''
                primarySourceElement = annotatedClass
            ]
        } 
        
        def private addResourceBundleGetter(MutableClassDeclaration annotatedClass, String basename) {
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
                            LOGGER.warn(String.format("No locale specified: '%s' used by default.", DEFAULT_LOCALE));
                        } else {
                            LOGGER.warn(String.format("No resource bundle '%s' available for locale '%s': '%s' used by default.", 
                                "«basename»", locale, DEFAULT_LOCALE));
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

        def private addAllMessageGetters(MutableClassDeclaration it) {
            val props = getProperties
            val basename = props.key
            val properties = props.value
            properties.forEach[p | addMessageGetter(p)]
            basename
        }
        
        def private removeAllMessageFields(MutableClassDeclaration it) {
            declaredFields.filter(messageFieldFilter).forEach[remove]
        }    

        def private addMessageGetter(MutableClassDeclaration it, Pair<String, String> property) {
            val ia = getAnnotation(I18n, context)
            val withBasicRules = ia.propertyFileEscapingRule === I18n.Escaping.basic
            
            val key = property.key
            val methodName = ia.keyToMethodName(key)
            val msg_ = property.value
            val msg = if (!withBasicRules) msg_ else msg_.getMessageReadyForMessageFormat
            
            addMethod(methodName) [
                val msgFormat = try {
                    new MessageFormat(msg)
                } catch(IllegalArgumentException e) {
                    addError("Invalid format: " + e.message)
                    new MessageFormat("")
                }
                val Format[] formats = msgFormat.formatsByArgumentIndex
                if(msgFormat.formats.length != formats.length) {
                    addWarning('Unused placeholders: ' + msg)
                }
            
                addParameter("locale", Locale.newTypeReference)
                formats.forEach [ Format format, idx |
                    addParameter("arg" + idx,
                        switch format {
                            NumberFormat: primitiveInt  // FIXME: integer only?
                            DateFormat: Date.newTypeReference()
                            default: string  // MessageFormat?
                        })
                ]
                varArgs = false
                returnType = if (ia.providerFormat === I18n.Provide.tagAndValue) Map.Entry.newTypeReference(string, string) 
                    else string
                docComment = msg
                static = true
                val escapedJavaMsg = StringEscapeUtils.escapeJava(msg)
                body = '''
                        String msg = null;
                        try {
                            msg = getResourceBundle(locale).getString("«key»");
                        } catch («MissingResourceException» e) {
                            msg = "«escapedJavaMsg»";
                            LOGGER.warn(String.format("No value available for '«key»', use by default: '%s'.", msg));
                        }
                        «IF formats.length > 0»
                        «IF withBasicRules»
                        msg = «FormatUtil».fromBasicToClassic(msg);
                        «ENDIF»
                        msg = «MessageFormat».format(msg, «parameters.map[simpleName].join(", ")»);
                        «ENDIF»
                        «IF ia.providerFormat === I18n.Provide.tagAndValue»
                        return new «AbstractMap.SimpleEntry»("«key»", msg);
                        «ELSE»
                        return msg;
                        «ENDIF»
                '''
                primarySourceElement = it
            ] 
        }
        
        def private getProperties(ClassDeclaration it) {
            val ia = getAnnotation(I18n, context)
            val folder = ia.getPropertyFileFolder(it)
            var basename = ia.propertyFileBasename
            val language = ia.propertyFileLanguage 

            val ef = getPropertyFile(folder, basename, language)
            
            if (ef === null) {
                addError('''
                    «IF basename.empty»
                    No basename provided: 
                    «ELSE»
                    Unable to find any property file under folder '«folder»' with basename '«basename»': 
                    «ENDIF»
                    use the fields of the annotated class '«it.simpleName»'.
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
            if (ef.empty) null 
            else {
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
                val fullbasename = source.relativize(parent).append(basename).toString.replace("/", ".") 
                fullbasename -> file
            }
        }
        
        def private findPropertyFiles(ClassDeclaration it, String folder, String basename) {
            val cls = it
            var sourcefolders = new HashSet(compilationUnit.filePath.projectSourceFolders) => [
            // FIXME: workaround for the bug https://bugs.eclipse.org/bugs/show_bug.cgi?id=476609.
            //        To be removed as soon as the bug is fixed.
                val ia = cls.getAnnotation(I18n, context)
                addAll(ia.getAdditionalSourceFolders(cls.compilationUnit.filePath.projectFolder))
// test:start            
println(">>>>> "+cls.compilationUnit.filePath+" is in source folders: ")
forEach[println("- " + it)]
// test:end          
            ]
            addWarning('''
            The full list of source folders: 
            «FOR f:sourcefolders»
            ---> «f»
            «ENDFOR»
            ''')  
            sourcefolders.map[it -> append(folder).findPropertyFilesWithBasename(basename, cls)].filter[!value.empty]  
        }
        
        def private Iterable<? extends Path> findPropertyFilesWithBasename(Path it, String basename, ClassDeclaration cls) {
            val paths = <Path>newLinkedHashSet
            if (! isFolder) {
                return paths
            }
            val index = basename.indexOf(LOCALE_SEP)
            val rootname = if (index <0) basename else basename.substring(0, index)
            
            paths += children.filter[fileExtension == "properties"]
                .filter[ val baseLastSegment = lastSegment.substring(0, lastSegment.indexOf("."))
                    (lastSegment.startsWith(rootname) 
                    && (baseLastSegment == basename || baseLastSegment.length < basename.length))
                ]
            paths += children.filter[isFolder].map[findPropertyFilesWithBasename(basename, cls)].flatten
            paths
        }

        def static private getAnnotation(ClassDeclaration it, Class<?> annotationType, 
            extension TransformationContext context
        ) {
            findAnnotation(annotationType.newTypeReference.type)
        }
        
        def static private getAnnotationPropertyValue(AnnotationReference it, String tag) {
            getValue(tag) as String
        }
        
        def static private getPropertyFileFolder(AnnotationReference it, ClassDeclaration annotatedClass) {
            (getAnnotationPropertyValue(I18N_FOLDER_PATH)?:"").trim
        }
        
        def static private getPropertyFileBasename(AnnotationReference it) {
            (getAnnotationPropertyValue(I18N_BASE_NAME)?:"").trim
        }
        
        def private Locale getPropertyFileLanguage(AnnotationReference it) {
            if (localeCache === null) {
                val l = (getAnnotationPropertyValue(I18N_LANGUAGE)?:"").trim
                localeCache = if (l.empty) {
                        DEFAULT_LANGUAGE
                    } 
                    else try {
                        new Locale.Builder().setLanguageTag(l).build
                    } catch(IllformedLocaleException e) {
                        addError('''The provided language code '«l»' is ill formed: 
                        default language will be used (see root basename property file or annotated class).''')
                        DEFAULT_LANGUAGE
                    }
            }
            localeCache
        }
        
        def private getPropertyFileEscapingRule(AnnotationReference it) {
            if (formattingRuleCache === null) {
                formattingRuleCache = try {
                        I18n.Escaping.valueOf(getEnumValue(I18N_ESCAPING_RULES).simpleName)
                    } catch(IllegalArgumentException e) {
                        DEFAULT_ESCAPING_RULE
                    } catch(NullPointerException e) {
                        DEFAULT_ESCAPING_RULE
                    }
            }
            formattingRuleCache
        }
        
        def private getProviderFormat(AnnotationReference it) {
            if (providerFormatCache === null) {
                providerFormatCache = try {
                        I18n.Provide.valueOf(getEnumValue(I18N_PROVIDE).simpleName)
                    }catch(IllegalArgumentException e) {
                        DEFAULT_PROVIDER_RULE
                    } catch(NullPointerException e) {
                        DEFAULT_PROVIDER_RULE
                    }
            }
            providerFormatCache
        }
        
        def private getMethodNameStyle(AnnotationReference it) {
            if (methodNameStyleCache === null) {
                methodNameStyleCache = try {
                        I18n.Style.valueOf(getEnumValue(I18N_STYLE).simpleName)
                    }catch(IllegalArgumentException e) {
                        DEFAULT_METHOD_NAME_STYLE
                    } catch(NullPointerException e) {
                        DEFAULT_METHOD_NAME_STYLE
                    }
            }
            methodNameStyleCache
        }
        
        def private getAdditionalSourceFolders(AnnotationReference it, Path project) {
            if (sourceListCache === null) {
                val extrasources = try {
                    getStringArrayValue(I18N_EXTRA_SOURCES)
                    } catch(IllegalArgumentException e) {
                        DEFAULT_EXTRA_SOURCES
                    } catch(NullPointerException e) {
                        DEFAULT_EXTRA_SOURCES
                    }
                sourceListCache = extrasources.map[project.append(it)]
            }
            sourceListCache
        }
        
        def private getPropertiesFromFile(Path propertyFile) {
            val reader = new StringReader(propertyFile.contents.toString)
            val bundle = new PropertyResourceBundle(reader)
            bundle.keySet.map[it -> bundle.getString(it)]
        }

        def private getPropertiesFromClass(ClassDeclaration it) {
            declaredFields.filter(messageFieldFilter).map[simpleName -> initializerAsString]
        }
        
        def private getInitializerAsString(FieldDeclaration it) {
            val Expression initializer = getInitializer 
            if(initializer === null) {
                addWarning("No initializer is provided: empty string will be used")
                return ""
            }  
            val value = initializer.toString.replaceAll("(\\r|\\n)", "")
            if(value.startsWith(STRING_DELIMITER)) {
                return value.substring(STRING_DELIMITER.length, value.length - STRING_DELIMITER.length)
            } 
            if (value.startsWith(TEMPLATE_DELIMITER)) {
                val v = value.substring(TEMPLATE_DELIMITER.length, value.length - TEMPLATE_DELIMITER.length)
                addWarning(format("Template expression '%s' is treated as simple string. No interpolation will be done.", v))  
                return v
            }
            addError(format("The initializer '%s' is neither a string nor a template expression. It will be used as it is.", value))   
            value
        }
        
        def private keyToMethodName(AnnotationReference it, String key) {
            switch methodNameStyle {
                case I18n.Style.classic:  {
                    CaseFormat.LOWER_CAMEL.to(CaseFormat.UPPER_UNDERSCORE, key)
                }
                case I18n.Style.camel: {
//                    CaseFormat.UPPER_UNDERSCORE.to(CaseFormat.LOWER_CAMEL, key).toFirstLower
                    CaseFormat.UPPER_UNDERSCORE.to(CaseFormat.LOWER_CAMEL, key)
                }
                default: {
                    key
                }
            }
        }
        
        def static private getBaseNameIfEmptyFromClass(ClassDeclaration it, String basename) {
            if (basename.empty) simpleName else basename
        }
        
        def static private getLocalizedBasename(String basename, Locale language) {
            basename + if (language == Locale.ROOT) "" else "_" + language
        }
        
    }

}

