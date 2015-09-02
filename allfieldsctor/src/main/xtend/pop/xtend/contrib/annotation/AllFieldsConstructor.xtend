package pop.xtend.contrib.annotation

import java.lang.annotation.Documented
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import java.util.regex.Pattern
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeParameterDeclarator
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference

@Target(ElementType.TYPE)
@Active(AllFieldsConstructorProcessor)
@Documented
annotation AllFieldsConstructor {
}

/**
 * Add a constructor without any argument
 */
class AllFieldsConstructorProcessor implements TransformationParticipant<MutableTypeParameterDeclarator> {

    override doTransform(List<? extends MutableTypeParameterDeclarator> elements,
        extension TransformationContext context) {
        elements.forEach[transform(context)]
    }

    def dispatch void transform(MutableClassDeclaration it, extension TransformationContext context) {
        val extension util = new AllFieldsConstructorProcessor.Util(context)
        addAllFieldsConstructor
    }

    def dispatch void transform(MutableConstructorDeclaration it, extension TransformationContext context) {
        val extension util = new AllFieldsConstructorProcessor.Util(context)
        makeAllFieldsConstructor
    }

    static class Util {
        extension TransformationContext context

        new(TransformationContext context) {
            this.context = context
        }

        def getNonTransientFields(MutableTypeDeclaration it) {
            declaredFields.filter[!static && ! transient && initializer == null && thePrimaryGeneratedJavaElement]
        }
        
        def needsAllFieldsConstructor(MutableClassDeclaration it) {
            !hasAllFieldsConstructor
            && (primarySourceElement as ClassDeclaration).declaredConstructors.isEmpty
        }
        
        def hasAllFieldsConstructor(MutableTypeDeclaration cls) {
            val expectedTypes = cls.allFieldsConstructorArgumentTypes
            cls.declaredConstructors.exists [
                parameters.map[type].toList == expectedTypes
            ]
        }
        
        def getAllFieldsConstructorArgumentTypes(MutableTypeDeclaration cls) {
            val types = newArrayList
            if (cls.superConstructor !== null) {
                types += cls.superConstructor.resolvedParameters.map[resolvedType]
            }
            types += cls.nonTransientFields.map[type]
            types
        }
        
        def String getConstructorAlreadyExistsMessage(MutableTypeDeclaration it) {
            '''Cannot create AllFieldsConstructor as a constructor with the signature "new(«allFieldsConstructorArgumentTypes.join(",")»)" already exists.'''
        }
        
        def addAllFieldsConstructor(MutableClassDeclaration it) {
            if (allFieldsConstructorArgumentTypes.empty) {
                val anno = findAnnotation(AllFieldsConstructor.findTypeGlobally)
                anno.addWarning('''There are no fields or only transient, this annotation has no effect''')
                return
            }
            if (hasAllFieldsConstructor) {
                addError(constructorAlreadyExistsMessage)
                return
            }
            addConstructor [
                primarySourceElement = declaringType.primarySourceElement
                makeAllFieldsConstructor
            ]
        }
        
        static val EMPTY_BODY = Pattern.compile("(\\{(\\s*\\})?)?")

        def makeAllFieldsConstructor(MutableConstructorDeclaration it) {
            if (declaringType.allFieldsConstructorArgumentTypes.empty) {
                val anno = findAnnotation(AllFieldsConstructor.findTypeGlobally)
                anno.addWarning('''There are no fields or only transient, this annotation has no effect''')
                return
            }
            if (declaringType.hasAllFieldsConstructor) {
                addError(declaringType.constructorAlreadyExistsMessage)
                return
            }
            if (!parameters.empty) {
                addError("Parameter list must be empty")
            }
            if (body !== null && !EMPTY_BODY.matcher(body.toString).matches) {
                addError("Body must be empty")
            }
            val superParameters = declaringType.superConstructor?.resolvedParameters ?: #[]
            superParameters.forEach [ p |
                addParameter(p.declaration.simpleName, p.resolvedType)
            ]
            val fieldToParameter = newHashMap
            declaringType.nonTransientFields.forEach [ p |
                p.markAsInitializedBy(it)
                val param = addParameter(p.simpleName, p.type.orObject)
                fieldToParameter.put(p, param)
            ]
            body = '''
                super(«superParameters.join(", ")[declaration.simpleName]»);
                «FOR arg : declaringType.nonTransientFields»
                    this.«arg.simpleName» = «fieldToParameter.get(arg).simpleName»;
                «ENDFOR»
            '''
        }
        
        def getSuperConstructor(TypeDeclaration it) {
            if (it instanceof ClassDeclaration) {
                if (extendedClass == object || extendedClass === null)
                    return null;
                return extendedClass.declaredResolvedConstructors.head
            } else {
                return null
            }
        }
        
        private def orObject(TypeReference ref) {
            if (ref === null) object else ref
        }

    }

}