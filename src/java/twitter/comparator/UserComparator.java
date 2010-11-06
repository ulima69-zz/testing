/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package twitter.comparator;

import java.util.Comparator;
import twitter4j.User;

/**
 *
 * @author wllyssys
 */
public class UserComparator implements Comparator<User>{

    public int compare(User t, User t1) {
        if(t.getName().compareTo(t1.getName())!=0)//se<0 t vem  na frente
            return t.getName().compareTo(t1.getName());
        else{
            return t.getScreenName().compareTo(t1.getScreenName());
        }
    }
}
