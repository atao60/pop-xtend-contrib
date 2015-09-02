package pop.xtend.contrib.annotation

import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.Map
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.EnumerationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.EnumerationValueDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestMethod
import org.springframework.web.bind.annotation.RestController

@Target(ElementType.TYPE)
@Active(HttpHandlerProcessor)
@Documented
annotation HttpHandler {
}

@Target(ElementType.METHOD)
annotation Get {
    String value
}

@Target(ElementType.METHOD)
annotation Post {
    String value
}

/**
 * - @HttpHandler === @RestController
 * - @Get === @RequestMapping(value = "someurl", method = RequestMethod.GET)
 * - @Post === @RequestMapping(value = "someurl", method = RequestMethod.POST) 
 */
class HttpHandlerProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration it, extension TransformationContext context) {
        extension val util = new HttpHandlerProcessor.Util(context)
        
        transformHandler
        transformRequest
        
    }
    
    private static class Util {
        static val VALUE_PROPERTY_TAG = "value"
        static val METHOD_PROPERTY_TAG = "method"
        
        val Map<Type, EnumerationValueDeclaration> requestMethodMap 
        
        extension TransformationContext context

        new(TransformationContext context) {
            this.context = context
            this.requestMethodMap = newHashMap => [
                val rmt = RequestMethod.findTypeGlobally as EnumerationTypeDeclaration
                put(Get.findTypeGlobally, rmt.findDeclaredValue(RequestMethod.GET.name))
                put(Post.findTypeGlobally, rmt.findDeclaredValue(RequestMethod.POST.name))
            ]
        }
        
        def void transformHandler(MutableClassDeclaration it) {
                addAnnotation(RestController.newAnnotationReference)
        }
        
        def void transformRequest(MutableClassDeclaration it) {
            declaredMethods.map[it -> requestData].filter[value !== null].forEach [
                key.transform(value)
            ]
        }
        
        def getRequestData(MutableMethodDeclaration it) {
            val annotation = annotations.findFirst[
                val atd = annotationTypeDeclaration
                requestMethodMap.keySet.contains(atd)
            ]
            if (annotation === null || annotation.getValue(VALUE_PROPERTY_TAG) === null) return null
            
            val reqType = annotation.annotationTypeDeclaration
            annotation.getValue(VALUE_PROPERTY_TAG) as String -> requestMethodMap.get(reqType)
        }
        
        def transform(MutableMethodDeclaration it, Pair<String, EnumerationValueDeclaration> requestData) {
            addAnnotation(RequestMapping.newAnnotationReference[
                set(VALUE_PROPERTY_TAG, requestData.key)
                setEnumValue(METHOD_PROPERTY_TAG, requestData.value)
            ])
        }
   }
   
}