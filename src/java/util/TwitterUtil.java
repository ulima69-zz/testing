/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package util;

/**
 *
 * @author wllyssys
 */
public class TwitterUtil {

    private static String URL_TEXT_TO_HTML_LINK = "((((ht|f)tps?:\\/\\/)|(www.))[a-zA-Z0-9_\\-.:#/~}?]+)";
    private static String TWITTER_HASHTAG_TO_HTML_LINK = "/(\\#[a-zA-Z0-9_%]*)/g";
    private static String TWITTER_USER_TO_HTML_LINK = "(?<![a-zA-Z0-9_\"'<>])@([a-z0-9_]{1,20})\\b";


    public static String parseURLTextToHTMLLink(String string) {
        return string.replaceAll(TwitterUtil.URL_TEXT_TO_HTML_LINK, "<a href=\"$1\" >$1</a>");
    }

    public static String parseTwitterHashtagToHTMLLink(String string) {
        return string.replaceAll(TwitterUtil.TWITTER_HASHTAG_TO_HTML_LINK, "<a href=\"http://www.twitter.com/search?q=$1\" >$1</a>");
    }

    public static String parseTwitterUserToHTMLLink(String string) {
        return string.replaceAll(TwitterUtil.TWITTER_USER_TO_HTML_LINK, "<a href=\"http://twitter.com/$1\">@$1</a>");
    }
    

}
