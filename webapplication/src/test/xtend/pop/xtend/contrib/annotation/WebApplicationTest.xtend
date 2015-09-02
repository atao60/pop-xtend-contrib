package pop.xtend.contrib.annotation

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

class WebApplicationTest {
    extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(WebApplication, HttpHandler, Get, Post)

    @Test def noMappingTest() {
        '''
        package popsuite.books.tries.spring.boot

        import pop.xtend.contrib.annotation.WebApplication

        @WebApplication
        class HelloApplication {
        
        }
        '''.assertCompilesTo(
            '''
package popsuite.books.tries.spring.boot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import pop.xtend.contrib.annotation.WebApplication;

@WebApplication
@SpringBootApplication
@SuppressWarnings("all")
public class HelloApplication {
  public static void main(final String[] args) {
    SpringApplication.run(HelloApplication.class, args);
  }
}
        ''')

    }

    @Test def withMappingTest() {
        '''
        package popsuite.books.tries.spring.boot

        import pop.xtend.contrib.annotation.Get
        import pop.xtend.contrib.annotation.HttpHandler
        import pop.xtend.contrib.annotation.WebApplication
        import org.springframework.web.bind.annotation.RequestMapping

        @WebApplication
        @HttpHandler
        class HelloApplication {
        
            @Get("/")
            def index() {
                "Greetings from Spring Boot!"
            }

        }
        '''.assertCompilesTo(
            '''
package popsuite.books.tries.spring.boot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import pop.xtend.contrib.annotation.Get;
import pop.xtend.contrib.annotation.HttpHandler;
import pop.xtend.contrib.annotation.WebApplication;

@WebApplication
@HttpHandler
@SpringBootApplication
@RestController
@SuppressWarnings("all")
public class HelloApplication {
  @Get("/")
  @RequestMapping(value = "/", method = RequestMethod.GET)
  public String index() {
    return "Greetings from Spring Boot!";
  }
  
  public static void main(final String[] args) {
    SpringApplication.run(HelloApplication.class, args);
  }
}
        ''')

    }

}