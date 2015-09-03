package pop.xtend.contrib.annotation

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class HttpHandlerTest {
    extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)
    
    @Test def simpleCaseChecking() {
        '''
        package popsuite.books.tries.spring.boot

        import pop.xtend.contrib.annotation.HttpHandler
        import pop.xtend.contrib.annotation.Get
        import pop.xtend.contrib.annotation.Post
        import org.springframework.web.bind.annotation.RequestMapping

        @HttpHandler  
        class HelloController {
        
            @Get("/")
            def index() {
                "Greetings from Spring Boot345!"
            }

            @Post("/")
            def index2() {
                "Greetings from Spring Boot345!"
            }

        }
        '''.assertCompilesTo(
            '''
package popsuite.books.tries.spring.boot;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import pop.xtend.contrib.annotation.Get;
import pop.xtend.contrib.annotation.HttpHandler;
import pop.xtend.contrib.annotation.Post;

@HttpHandler
@RestController
@SuppressWarnings("all")
public class HelloController {
  @Get("/")
  @RequestMapping(value = "/", method = RequestMethod.GET)
  public String index() {
    return "Greetings from Spring Boot345!";
  }
  
  @Post("/")
  @RequestMapping(value = "/", method = RequestMethod.POST)
  public String index2() {
    return "Greetings from Spring Boot345!";
  }
}
        ''')

    }

}