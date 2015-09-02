Xtend Active Annotations - Contribution
==============================

A set of Xtend Active Annotations.

Features
=======

@I18n
------
Creates a statically typed facade for localization ResourceBundles.
The generated methods take an argument for each placeholder in the message.
The type of the argument will be inferred from the message format.

Furthermore, with the escaping option "basic", no more need to escape 
single quotes. The translators will love you... 

```property files i18n/converter_en.properties
TITLE_404 Lost?
MESSAGE_404 Come back to the <a id='welcome' href='{0}'>welcome page</a>
```

```property files i18n/converter_fr.properties
TITLE_404 Perdu ?
MESSAGE_404 Revenir à la <a id='welcome' href='{0}'>page d'accueil</a>
```

```xtend
@NoArgsConstructor(visibility=Visibility.PRIVATE)
@I18n(folder="i18n", basename="converter", language="en", escaping="basic", provide="valueAlone")
class I18nMessages {
    def static void main(String[] args) {
        val locale = Locale.FRENCH
        println(locale.TITLE_404)
        println(locale.MESSAGE_404("/"))
    }
}
```

@AllFieldsConstructor
----------
Create a class constructor with all the non-transient and non-static fields declared by the annotated class.
```xtend
@Accessors
@AllFieldsConstructor
class Person {
    val String id
    String firstName
    String lastName
    int age
}
```

@NoArgsConstructor
-----------------
Create a class constructor without any argument. It can be public or private.

That allows to define a private constructor for classes which must not be instanciated. 
See an example above with @I18n. 

@WebApplication, @HttpHandler, @Get and @Post
---------
Set up a web application in [Sinatra](http://www.sinatrarb.com/) style 
using [Spring Boot](http://projects.spring.io/spring-boot/).
```xtend
@WebApplication @HttpHandler
class HelloApplication {
    @Get("/") def index() {
        "Greetings from Spring Boot!"
    }
}
```


