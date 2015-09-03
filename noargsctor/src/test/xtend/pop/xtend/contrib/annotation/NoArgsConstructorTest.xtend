package pop.xtend.contrib.annotation

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class NoArgsConstructorTest {
    extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

    @Test def fullCodeChecking() {
        '''
        package popsuite.books.tries.spring.boot

        import pop.xtend.contrib.annotation.NoArgsConstructor

        @NoArgsConstructor
        class HelloApplication {
        }
        '''.assertCompilesTo(
            '''
package popsuite.books.tries.spring.boot;

import pop.xtend.contrib.annotation.NoArgsConstructor;

@NoArgsConstructor
@SuppressWarnings("all")
public class HelloApplication {
  public HelloApplication() {
    
  }
}
        ''')
    }
}