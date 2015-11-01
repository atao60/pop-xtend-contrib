Xtend Active Annotations - Contribution
==============================

A set of Xtend Active Annotations.

Features
=======

[@I18n](../i18n/README.md)
------
Creates a statically typed facade for internationalization ResourceBundles.
The generated methods take an argument for each placeholder in the message.
The type of the argument will be inferred from the message format.


[@AllFieldsConstructor](../allfieldsctor/README.md)
----------
Create a class constructor with all the non-transient and non-static fields declared by the annotated class.


[@NoArgsConstructor](../noargsctor/README.md)
-----------------
Create a class constructor without any argument. It can be public or private. 
That allows to define a private constructor for classes which must 
not be instanciated. See an example above with @I18n.

[@WebApplication, @HttpHandler, @Get and @Post](../webapplication/README.md)
---------
Set up a web application in [Sinatra](http://www.sinatrarb.com/) style 
using [Spring Boot](http://projects.spring.io/spring-boot/).



