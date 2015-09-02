Xtend - Active Annotations : Internationalization 
==============================

Rational
------

Creates a statically typed facade for internationalization ResourceBundles.
The generated methods take an argument for each placeholder in the message.
The type of the argument will be inferred from the message format.

Furthermore, with the escaping option `basic`, no more need to escape 
single quotes. The localizers will love you... 

Usage
-----

Create property files, e.g.:

```property file i18n/converter_en.properties
TITLE_404 Lost?
MESSAGE_404 Come back to the <a id='welcome' href='{0}'>welcome page</a>
```

```property file i18n/converter_fr.properties
TITLE_404 Perdu ?
MESSAGE_404 Revenir à la <a id='welcome' href='{0}'>page d'accueil</a>
```

Then create a message class which will render any existing property file:

```xtend
@NoArgsConstructor(visibility=Visibility.PRIVATE)
@I18n(folder="i18n", basename="converter", language="en", escaping="basic", provide="valueAlone")
class I18nMessages {}
```

Now the messages can be used by calling the static generated functions:

```xtend
import static extension I18nMessages.*
class Application {
    def static void main(String[] args) {
        val locale = Locale.FRENCH
        println(locale.TITLE_404)
        println(locale.MESSAGE_404("/"))
    }
}
```

Parameters
---------

- basename: @I18n searches all the property files with the given basename, e.g. with `basename="msg"`: msg.properties, msg_fr.properties, msg_fr_FR.properties, msg_fr_CA.properties, msg_en.properties, msg_en_EN.properties, msg_en_US.properties ...  
If no basename is given, the simple name of the annotated class is used as basename.  
By default, the simple name of the annotated class.
   
- folder: @I18n searches the property files inside all the sub folders of any resource 
folder but only under the given sub folder, e.g. for a standard Maven project 
with `folder="i18n"`: src/main/java/i18n, src/main/resources/i18n...  
By default, the whole set of subfolders for each source folder is scanned. 

- language: @I18n uses the first property file found for that language (see above) to retrieve the list of keys to manage.
This paramater is used only to generate the static functions bound to those keys.  
By default, the root property files, e.g. with `basename="msg"`: `msg.properties`.  
If no property files are found, the final fields of the annotated class are used to set up the list of keys.

- escaping: two set of escaping rules are available, `classic` and `basic`.  
By default: `basic`.  
The set of rules are:
  * classic: the escaping rules are the same as those of [MessageRule](http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html)
  * basic: the escaping rules stay very close of those of [MessageRule](http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html) but with 2 changes:
    * a standalone single quote is interpreted as a single quote whatever the kind of messages, i.e. with or without parameters,
    * left and right braces must be escaped with enclosing single quotes, i.e. "'{'" and "'}'". It's the only case where single quotes can be used as escaping characters.
        
- provide: specify if the generated static functions must provide either the property value alone or a pair tag and value.  
By default: tag and value.

References
--------

- [Better I18n in Java](http://blog.efftinge.de/2013/09/better-i18n-in-java.html), Sven Efftinge, with the code available [here](https://github.com/eclipse/xtext/tree/master/examples/org.eclipse.xtend.examples-container/contents/xtend-annotation-examples/src/i18n)

- [Active annotations use cases](https://blogs.itemis.de/leipzig/archives/907), Jörg Reichert, with the code available [here](https://github.com/joergreichert/ActiveAnnotationsExamples/tree/master/nls)

- [Xtend - Active Annotations : Localization](https://oehme.github.io/2014/11/28/xtend-active-annotations-localization.html),  Stefan Oehme, with the code available [here](https://github.com/oehme/xtend-contrib/blob/master/xtend-contrib/src/main/java/de/oehme/xtend/contrib/localization/Messages.xtend)

- [Bug 30297 - fmt strips quotes when using parameter](https://bz.apache.org/bugzilla/show_bug.cgi?id=30297). A good summary, even if the issue is not related to *FreeMarker*.



     