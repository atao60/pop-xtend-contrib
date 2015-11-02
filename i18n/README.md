Xtend - Active Annotations : Internationalization 
==============================

Rational
------

Creates a statically typed facade for internationalization ResourceBundles.
The facade provides a static method for each pair key/message of a given property files.
Those methods take an argument for each placeholder in the message pattern.
The type of the argument will be inferred from the message format.

Furthermore, with the default escaping option `basic`, no more need to escape standalone
single quotes. The localizers will love you! 

Usage
-----

Create property files, e.g.:

```properties
#property file i18n/converter_en.properties
TITLE_404 Lost?
MESSAGE_404 Come back to the <a id='welcome' href='{0}'>welcome page</a>
```

```properties
#property file i18n/converter_fr.properties
TITLE_404 Perdu ?
MESSAGE_404 Revenir à la <a id='welcome' href='{0}'>page d'accueil</a>
```

Then create a class which with annotation @I18n.

```xtend
@NoArgsConstructor(visibility=Visibility.PRIVATE)
@I18n(folder="i18n", basename="converter", language="en", escaping="basic", mapping="with", provide="valueAlone")
class I18nMessages {}
```

The parameters 'folder', 'basename' and 'language' are used to search the property file to be used to generate the static methods.

Now the messages can be retrieve by calling the static generated functions:

```xtend
import static extension I18nMessages.*
class Application {
    def static void main(String[] args) {
        val locale = Locale.FRENCH
        println(locale.TITLE_404)
        println(locale.MESSAGE_404("/"))
        
       val __ = locale.messages
       println(__.TITLE_404)
       println(__.MESSAGE_404("/"))
    }
}
```

Parameters
---------

* **folder**: @I18n searches the property files inside all the sub folders of any resource 
folder but only under this given sub folder. E.g. for a standard Maven project 
with `folder="i18n"`: src/main/java/i18n, src/main/resources/i18n...  
By default, the whole set of subfolders for each source folder is scanned. 

* **basename**: @I18n searches all the property files with the given basename. E.g. with `basename="msg"`: msg.properties, msg_fr.properties, msg_fr_FR.properties, msg_fr_CA.properties, msg_en.properties, msg_en_EN.properties, msg_en_US.properties ...  
By default, the simple name of the annotated class.
   
* **language**: @I18n uses the first property file found for that language (see above) to retrieve the list of keys to manage.
This parameter is used to generate the static functions bound to those keys and as the default language at runtime.  
By default, the root property files, e.g. with `basename="msg"`: `msg.properties`.  
If no property files are found, the final fields of the annotated class are used to set up the list of keys.

* **escaping**: two set of escaping rules are available, `classic` and `basic`.  
By default: `basic`.  
The set of rules are:
      * **classic**: see [MessageRule](http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html)
      * **basic**: as [MessageRule](http://docs.oracle.com/javase/8/docs/api/java/text/MessageFormat.html) but with 2 differences:    
            * a standalone single quote is <strong>always</strong> interpreted as a single quote whatever the kind of messages, 
      i.e. with or without parameters,  
            * left and right braces must be escaped with enclosing single quotes, i.e. "'{'" and "'}'". It's the only case where single quotes can be used as escaping characters.
        
* **provide**: specify if the generated static functions must provide either the property value alone or a pair tag and value.  
By default: tag and value.

* **mapping**: specify if a map with all the static methods must be provided.

References
--------

- [Better I18n in Java](http://blog.efftinge.de/2013/09/better-i18n-in-java.html), Sven Efftinge, 04/09/2013, with the code available [here](https://github.com/eclipse/xtext/tree/master/examples/org.eclipse.xtend.examples-container/contents/xtend-annotation-examples/src/i18n)

- [Active annotations use cases](https://blogs.itemis.de/leipzig/archives/907), Jörg Reichert, 17/03/2014, with the code available [here](https://github.com/joergreichert/ActiveAnnotationsExamples/tree/master/nls)

- [Xtend - Active Annotations : Localization](https://oehme.github.io/2014/11/28/xtend-active-annotations-localization.html),  Stefan Oehme, 28/11/2014, with the code available [here](https://github.com/oehme/xtend-contrib/blob/master/xtend-contrib/src/main/java/de/oehme/xtend/contrib/localization/Messages.xtend)

- [Bug 30297 - fmt strips quotes when using parameter](https://bz.apache.org/bugzilla/show_bug.cgi?id=30297). A good summary, even if the issue is not related to *FreeMarker*.



     