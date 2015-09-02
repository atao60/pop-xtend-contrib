package pop.xtend.contrib.annotation

import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration

@Target(ElementType.TYPE)
@Active(NoArgsConstructorProcessor)
@Documented
annotation NoArgsConstructor {
    Visibility visibility = Visibility.PUBLIC
}

/**
 * Add a constructor without any argument
 */
class NoArgsConstructorProcessor extends AbstractClassProcessor {

    static val VISIBILITY_PROPERTY_NAME = "visibility"


    override doTransform(MutableClassDeclaration it, extension TransformationContext context) {
        val naca = getAnnotation(NoArgsConstructor, context)
        val cls = it
        addConstructor() [
            
            visibility = naca.getAnnotationPropertyValue(VISIBILITY_PROPERTY_NAME)
            primarySourceElement = cls
            body = ''''''
        ]
    }
    
    def static private getAnnotationPropertyValue(AnnotationReference it, String tag) {
        Visibility.valueOf(getEnumValue(tag).simpleName)
    }

    def static private getAnnotation(ClassDeclaration it, Class<?> annotationType, 
        extension TransformationContext context
    ) {
        findAnnotation(annotationType.newTypeReference.type)
    }
        
}