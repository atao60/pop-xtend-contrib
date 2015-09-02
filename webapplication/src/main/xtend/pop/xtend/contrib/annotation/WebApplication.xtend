package pop.xtend.contrib.annotation

import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.eclipse.xtend.lib.macro.AbstractClassProcessor

@Target(ElementType.TYPE)
@Active(WebApplicationProcessor)
@Documented
annotation WebApplication {
}

/**
 * Set up a web application in Sinatra style using Spring Boot. 
 * 
 * Add annotation:
 * <li> @SpringBootApplication i.e. @Configuration + @EnableAutoConfiguration + @ComponentScan
 */
class WebApplicationProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration it, extension TransformationContext context) {
       
        addAnnotation(newAnnotationReference(SpringBootApplication)) 
        
        val cls = it
        addMethod("main") [
            visibility = Visibility::PUBLIC
            static = true
            returnType = primitiveVoid
            val springApplicationType = newTypeReference(SpringApplication)
            val parameterName = "args"
            addParameter(parameterName, newArrayTypeReference(string))
            body = '''
                «springApplicationType».run(«cls.simpleName».class, «parameterName»);
                '''
            primarySourceElement = cls
        ]
    }

}