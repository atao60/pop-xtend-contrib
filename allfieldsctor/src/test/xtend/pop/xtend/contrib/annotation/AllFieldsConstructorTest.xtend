package pop.xtend.contrib.annotation

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class AllFieldsConstructorTest {
    extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

    @Test def fullCodeChecking() {
        '''
        package popsuite.books.tries.spring.boot

        import pop.xtend.contrib.annotation.AllFieldsConstructor

        @AllFieldsConstructor
        class HelloApplication {
            val String m1
            String m2
            transient String m3
        }
        '''.assertCompilesTo(
            '''
package popsuite.books.tries.spring.boot;

import pop.xtend.contrib.annotation.AllFieldsConstructor;

@AllFieldsConstructor
@SuppressWarnings("all")
public class HelloApplication {
  private final String m1;
  
  private String m2;
  
  private transient String m3;
  
  public HelloApplication(final String m1, final String m2) {
    super();
    this.m1 = m1;
    this.m2 = m2;
  }
}
        ''')
    }
}