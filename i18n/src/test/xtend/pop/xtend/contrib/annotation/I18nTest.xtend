package pop.xtend.contrib.annotation

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

import static org.junit.Assert.assertEquals
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration 
import org.eclipse.xtend.lib.macro.declaration.Visibility

class I18nTest {
    
    extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(I18n)
        
    @Test def void testStringDefaultValue() {
        '''
            package i18n

            import pop.xtend.contrib.annotation.I18n
            
            @I18n
            class MyMessages {
                val GREETING = "Hello {0}"
                val DATE_MESSAGE = "Today, is ${0,date}."
            }
        '''.compile [
            val extension TransformationContext ctx = transformationContext
            val MutableClassDeclaration clazz = findClass('i18n.MyMessages')
            
            assertEquals(2, clazz.declaredMethods.filter[visibility == Visibility.PUBLIC].size)
            
        ]
    }

}