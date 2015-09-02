package pop.xtend.contrib.annotation.util

import org.junit.Test
import static org.junit.Assert.*
import static org.hamcrest.CoreMatchers.*
import java.text.MessageFormat

class FormatUtilTest {
    
    @Test
    def emptyMessageTest() {
        val msg = ""
        
        assertThat(FormatUtil.fromBasicToClassic(msg) , is(equalTo(msg)))
    }

    @Test
    def normalMessageTest() {
        val msg = "any string without neither left brace nor single quote"
        
        assertThat(FormatUtil.fromBasicToClassic(msg) , is(equalTo(msg)))
    }

    @Test
    def messageWithSingleQuoteTest() {
        val msg = "any string without left brace but with single quotes, e.g: a middle ' and a final '"
        
        assertThat(FormatUtil.fromBasicToClassic(msg) , is(equalTo(msg)))
    }

    @Test
    def messageWithParamTest() {
        val msg = "a string with parameter, e.g: a middle {0} and a final {1}"
        val result = FormatUtil.fromBasicToClassic(msg)
        
        assertThat(result , is(equalTo(msg)))
    }

    @Test
    def interpolatedMessageWithParamTest() {
        val msg = "a string with parameter, e.g: a middle {0} and a final {1}"
        val classic = FormatUtil.fromBasicToClassic(msg)
        val interpollated = MessageFormat.format(classic, "string", "string")
        val expected = "a string with parameter, e.g: a middle string and a final string"
        
        assertThat(interpollated , is(equalTo(expected)))
    }

    @Test
    def messageWithParamAndQuoteTest() {
        val msg = "a string with parameter and quote, e.g: a middle ' with {0} and an other {1} with ' and other stuff."
        val classic =  "a string with parameter and quote, e.g: a middle '' with {0} and an other {1} with '' and other stuff."
        val result = FormatUtil.fromBasicToClassic(msg)
        
        assertThat(result , is(equalTo(classic)))

        val msg2 = "a string with parameter and quote, e.g: a middle ' with {0} and an other {1} with '."
        val classic2 =  "a string with parameter and quote, e.g: a middle '' with {0} and an other {1} with ''."
        val result2 = FormatUtil.fromBasicToClassic(msg2)
        
        assertThat(result2 , is(equalTo(classic2)))
    }

    @Test
    def interpolatedMessageWithParamAndQuoteTest() {
        val msg = "a string with parameter and quote, e.g: a middle ' with {0} and an other {1} with ' and other stuff."
        val classic = FormatUtil.fromBasicToClassic(msg) 
        val interpollated = MessageFormat.format(classic, "string", "string")
        val expected = "a string with parameter and quote, e.g: a middle ' with string and an other string with ' and other stuff."
        
        assertThat(interpollated , is(equalTo(expected)))

        val msg2 = "a string with parameter and quote, e.g: a middle ' with {0} and an other {1} with '."
        val classic2 = FormatUtil.fromBasicToClassic(msg2) 
        val interpollated2 = MessageFormat.format(classic2, "string", "string")
        val expected2 = "a string with parameter and quote, e.g: a middle ' with string and an other string with '."
        
        assertThat(interpollated2 , is(equalTo(expected2)))
    }

    @Test
    def messageWithEscapedParamTest() {
        val msg = "a string with parameter and quote, e.g: a middle ' with {0} and an other escaped '{'1'}' with ' and other stuff."
        val classic =  "a string with parameter and quote, e.g: a middle '' with {0} and an other escaped '{1}' with '' and other stuff."
        val result = FormatUtil.fromBasicToClassic(msg)
        
        assertThat(result , is(equalTo(classic)))

    }

   @Test
    def interpolatedMessageWithEscapedParamTest() {
        val msg = "a string with parameter and quote, e.g: a middle ' with {0} and an other escaped '{'1'}' with ' and other stuff."
        val classic = FormatUtil.fromBasicToClassic(msg)
        val interpollated = MessageFormat.format(classic, "string")
        val expected = "a string with parameter and quote, e.g: a middle ' with string and an other escaped {1} with ' and other stuff."
        
        assertThat(interpollated , is(equalTo(expected)))
    }
    
   @Test
    def namedMessageFormatFirstExampleTest() {
        val msg = "They've {0} java tests and we've {1} java tests."
        val classic = FormatUtil.fromBasicToClassic(msg)
        assertThat(classic, is(equalTo("They''ve {0} java tests and we''ve {1} java tests.")))
        val interpollated = MessageFormat.format(classic, "seven", "ten")
        val expected = "They've seven java tests and we've ten java tests."
        
        assertThat(interpollated , is(equalTo(expected)))
    }
    
    @Test
    def namedMessageFormatSecondExampleTest() {
        val msg = "Use ''{'amount'}'' to indicate negative amount"
        val classic = FormatUtil.fromBasicToClassic(msg) 
        assertThat(classic, is(equalTo("Use '''{amount}''' to indicate negative amount")))
        val interpollated = MessageFormat.format(classic, null)
        val expected = "Use '{amount}' to indicate negative amount"
        
        assertThat(interpollated , is(equalTo(expected)))

    }

    @Test
    def namedMessageFormatThirdExampleTest() {
        val msg = " '{0}' is full"
        val classic = FormatUtil.fromBasicToClassic(msg)
        assertThat(classic , is(equalTo(" ''{0}'' is full")))
        val interpollated = MessageFormat.format(classic, "Mydisk")
        val expected = " 'Mydisk' is full"
        
        assertThat(interpollated , is(equalTo(expected)))
    }
    
    @Test
    def messageFormatFirstExample() {
        val msg = "'{'''}'"
        val classic = FormatUtil.fromBasicToClassic(msg)
        assertThat(classic , is(equalTo("'{''}'")))
        val interpollated = MessageFormat.format(classic, null)
        val expected = "{'}"
        
        assertThat(interpollated , is(equalTo(expected)))
    }
    
}