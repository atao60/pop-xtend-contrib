Xtend - Contribution
====================

A set of tools for Xtend.

At the moment it contains only [annotations](annotations/README.md)

Extension Maven and Travis-CI
---------------
The pop-xtend-contrib projects use Maven extensions. It requires Maven 3.3.1 or above.
But at the moment Travis-CI can't be configured with such a version. Then to deploy the
jar archive of annotations on github/snapshot, Maven must be used with the profile
"maven-repo-update" activited from Travis-CI script.