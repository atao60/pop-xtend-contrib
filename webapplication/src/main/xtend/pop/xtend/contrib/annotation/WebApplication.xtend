package pop.xtend.contrib.annotation

import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.springframework.boot.SpringApplication
import org.springframework.boot.autoconfigure.SpringBootApplication

/**
 * Set up a web application in <a href="http://www.sinatrarb.com/">Sinatra</a> style 
 * using <a href="http://projects.spring.io/spring-boot/">Spring Boot</a>. 
 * 
 * Add annotation:
 * <li> @SpringBootApplication i.e. @Configuration + @EnableAutoConfiguration + @ComponentScan
 * 
 * If it doesn't exists, create a static method "main".
 * 
 * Note. If you get a warning "<pre>Cannot call method 'isVoid' on a inferred type reference before
 * the compilation phase. Check isInferred() before calling any methods.</pre>", add an explicit return type
 * to the method. 
 */
@Target(ElementType.TYPE)
@Active(WebApplicationProcessor)
@Documented
annotation WebApplication {
}

class WebApplicationProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration it, extension TransformationContext context) {
        extension val util = new Util(context)
        
        addAnnotation(newAnnotationReference(SpringBootApplication)) 
        
        if (mainMethodAlreadyExists) {
            wrapMainMethod
        } else {
            addMainMethod
        }
        
    }
    
    private static class Util {
        val extension TransformationContext context

        static val  MAIN_METHOD_NAME = "main"
        
        new(TransformationContext context) {
            this.context = context
        }

        private def isMainMethodAlreadyExists(ClassDeclaration it) {
            findDeclaredMethod(MAIN_METHOD_NAME, newArrayTypeReference(string)) !== null
        } 
        
        private def wrapMainMethod(MutableClassDeclaration it) {
            
            val mainMethod = findDeclaredMethod(MAIN_METHOD_NAME, newArrayTypeReference(string))
            val internalMethodName = "wrapped" + MAIN_METHOD_NAME.toFirstUpper
            val originalArguments = mainMethod.parameters
            val originalArgumentsJoined = originalArguments.map[simpleName].join(", ")
            val originalBody = mainMethod.body
            val originalReturnType = mainMethod.returnType
            
            val cls = it
//            val springApplicationType = newTypeReference(SpringApplication)
// TODO: create a bug report? Here newTypeReference(SpringApplication) doesn't generate an import
            mainMethod.body = [
                val isMethodReturnTypeVoid = originalReturnType === null || originalReturnType.isVoid
                '''
                    «/*springApplicationType*/SpringApplication.name».run(«cls.simpleName».class, «originalArgumentsJoined»);
                    
                    «IF ! isMethodReturnTypeVoid»return «ENDIF»«internalMethodName»(«originalArgumentsJoined»);
            ''']

            addMethod(internalMethodName) [
                visibility = Visibility.PRIVATE
                static = true
                returnType = originalReturnType
                val method = it
                originalArguments.forEach[method.addParameter(simpleName, type)]
                body = originalBody
                primarySourceElement = method
            ]
            
        }
        
        private def addMainMethod(MutableClassDeclaration it) {
            val cls = it
            addMethod(MAIN_METHOD_NAME) [
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
    
}