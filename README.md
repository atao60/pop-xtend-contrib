Xtend - Contribution j2x-on-openshift [![Build Status](https://travis-ci.org/atao60/pop-xtend-contrib.svg?branch=master)](https://travis-ci.org/atao60/pop-xtend-contrib)
====================

A set of tools for [Xtend](https://eclipse.org/xtend).

At the moment it contains only [annotations](all-annotations/README.md). Some of them use Spring.

Distribution
----

Each contribution is available as a *Maven* artifact. 

There is also an artifact "all-annotations" gathering all the contributions.

All the artifacts are available from [Atao60 Snapshots repository](https://github.com/atao60/snapshots).

Requirements
----

This project requires:

- JDK 1.8
- [Maven](https://maven.apache.org/) 3.3.1 or above
- a [GitHub](https://github.com) account,
- a [Travis-CI](https://travis-ci.org/) account.

When working under [Eclipse](https://projects.eclipse.org/), it requires:

- [Xtend SDK](https://eclipse.org/xtend/download.html) 
- [M2Eclipse*)(http://www.eclipse.org/m2e/).

Warning (30/10/2015)
-----   

This project uses:  
- *Xtend* 2.9.0.beta6: even if it seems there are no issues about it, it's still a beta version. 
- [Maven](https://maven.apache.org/) 3.3.1 or above. It provides the extension support (see file .mvn/extensions.xml). Many tools doesn't support it yet, e.g. *Travis-CI* or [M2Eclipse](http://eclipse.org/m2e/), more details below.

Extension *Maven* and *Travis-CI*
----

The [pop-xtend-contrib](https://github.com/atao60/pop-xtend-contrib) projects use *Maven* extensions: it requires *Maven* 3.3.1 or above.
But at the moment *Travis-CI* can't be configured with such a *Maven* version. Then to deploy the
jar archives of annotations on *Atao60 Snapshots repository*, 
*Maven* must be used with the profile `maven-repo-update` activited from the *Travis-CI* script.
    
Build
----

To check if everything is ready:

```bash
    mvn clean package
```

To be able to use locally the annotations without publishing them:

```bash
    mvn clean install
```
### Publish

Continuous integration and deployment are managed with *Travis-CI* service. As soon as a commit is pushed to the [pop-xtend-contrib repository](https://github.com/atao60/pop-xtend-contrib) on *Github*, a continuous integration cycle is launched:

```bash
    cd <workspace>/pop-xtend-contrib  
    git commit -m "New update"  
    git push  
```

If it passes, then a new snapshot version of the artifact becomes available from [Atao60 Snapshots repository](https://github.com/atao60/snapshots). 
    
### Todo

Create a pom artifact with artifactId=no-spring and only the contributions without any dependency with *Spring*.



         

