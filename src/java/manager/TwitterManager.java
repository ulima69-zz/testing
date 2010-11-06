/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package manager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import twitter.comparator.UserComparator;
import twitter4j.IDs;
import twitter4j.PagableResponseList;
import twitter4j.Status;
import twitter4j.Trend;
import twitter4j.Trends;
import twitter4j.Twitter;
import twitter4j.TwitterException;
import twitter4j.TwitterFactory;
import twitter4j.User;
import twitter4j.http.AccessToken;

/**
 *
 * @author Administrador
 */
public class TwitterManager {

    private static TwitterManager instance;
    private static AccessToken accessToken;
    private static TwitterFactory factory;
    private static Twitter twitter;

    private TwitterManager() {
        //ConfigurationBuilder configurator = new ConfigurationBuilder();
        //configurator.setHttpConnectionTimeout(80000);
        //configurator.setHttpProxyHost("172.16.10.1");
        //configurator.setHttpProxyPort(128);
        this.accessToken = new AccessToken(TokenManager.TOKEN, TokenManager.TOKEN_SECRET);
        //this.factory = new TwitterFactory(configurator.build());
        this.factory = new TwitterFactory();
        this.twitter = factory.getOAuthAuthorizedInstance(TokenManager.CONSUMER_KEY, TokenManager.CONSUMER_SECRET, accessToken);
    }


    public static TwitterManager getInstance() {
        if(instance==null)
            return new TwitterManager();
        return instance;
    }


    public static List<User> getUserFriendsList() {
        List<Status> status = null;
        List<User> users = null;
        try {
            status = TwitterManager.twitter.getFriendsTimeline();

            if(status!=null && !status.isEmpty()){
                users = new ArrayList<User>();
                for (Status status1 : status) {
                    users.add((User)status1.getUser());
                }
                
                return users;
            }
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public static List<User> getAllUserFriends() {
        List<User> todos = null;//guarda a listagem completa de amigos
        try {
            IDs ids = TwitterManager.twitter.getFriendsIDs();
            int[] array = ids.getIDs();
            System.out.println("Numero de amigos: " + array.length);

            if(array.length>0){//existem amigos e precisam ser buscados
                todos = new ArrayList<User>();
                PagableResponseList list = TwitterManager.twitter.getFriendsStatuses();//pego a primeira listagem
                todos.addAll(list);

                //vou pagina a lista de amigos para pegar todos
                long nextCursor = list.getNextCursor();
                while(nextCursor!=0){//enquanto houverem mais indicadores para lista de amigos
                    PagableResponseList list2 = TwitterManager.twitter.getFriendsStatuses(nextCursor);
                    todos.addAll(list2);
                    nextCursor = list2.getNextCursor();
                }

                //printUserFriendList(todos);

                return todos;
            }else{//nao existem amigos
                System.out.println("Voce ainda não tem nenhum amigo");
                return null;
            }
        } catch (TwitterException ex) {
            //Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
            ex.printStackTrace();
        }
        return null;
    }

    public static List<User> sortFriendsListByName(List<User> list) {
        List<User> sortedList = new ArrayList<User>();
        sortedList.addAll(list);
        Collections.sort(sortedList, new UserComparator());
        return sortedList;        
    }

    public static void printUserFriendList(List<User> list) {
        for (User user : list) {
            System.out.println("################################################");
            System.out.println("Nome: "+user.getName());
            System.out.println("Screen name: "+user.getScreenName());
            System.out.println("LOcation"+user.getLocation());
            //System.out.println("User url: "+user.getURL().toString());
            System.out.println("IMage: "+user.getProfileImageURL().toString());
            System.out.println("################################################");
            System.out.println("");
            System.out.println("");
        }
    }

    /**
     * Contem uma lista de Status
     * @return
     */
    public static List getUserTimeline() {
        try {
            return TwitterManager.twitter.getUserTimeline();
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public static List<Status> getUserFriendsTimeline() {
        try {
            return TwitterManager.twitter.getFriendsTimeline();
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public static Integer getQtdeAmigos() {
        try {
            IDs ids = TwitterManager.twitter.getFriendsIDs();
            if(ids!=null){
                int[] array = ids.getIDs();
                if(array!=null)
                    return array.length;
            }
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    //talvez nao ira funcionar pois a lista de amigos nao é paginada
    public static int getQtdePaginasAmigos() {
        if(getQtdeAmigos()!=null){
            if(getQtdeAmigos()>0){
                if(getQtdeAmigos()<=100)return 1;//apenas uma pagina
                if(getQtdeAmigos()%100==0)return getQtdeAmigos()/100;//multiplos de 100
                if(getQtdeAmigos()%100!=0)return (getQtdeAmigos()/100)+1;//multiplos de 100 + outras pagina contendo o restante
            }else{
                return 0;//nao tem nenhum amigo, enat nao tem nenhuma página
            }
        }
        return 0;
    }

        /**
     * Retorna uma lista de 7 Trends, uma para dia da semana. Cada Trends contem um array com 30 elementos
     * @return
     */
    public static List<Trends> getTrendsSemanais() {
        try {
            return TwitterManager.twitter.getWeeklyTrends();
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }


    /**
     * A lista retornada contem 24 elementos, representando as ultimas 24horas. Cada elementos comtem um array
     * com 20 elementos, representando os Trends daquela hora
     * @return
     */
    public static List<Trends> getTrendsDiarios() {
        try {
            return TwitterManager.twitter.getDailyTrends();
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public static List<Trend> getTrendsAgora() {
        try {
            Trends trends = TwitterManager.twitter.getCurrentTrends();
            return Arrays.asList(trends.getTrends());
        } catch (TwitterException ex) {
            Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public static List<String> getHashtagsDaTimeline() {
        List<Status> timeline = getUserFriendsTimeline();
        List<String> listaHasgtag = new ArrayList<String>();

        if (timeline!=null && !timeline.isEmpty()) {
            for (Status status : timeline) {
                List<String> lista = getHashtagsByStatus(status);
                if(lista!=null)
                    listaHasgtag.addAll(lista);
            }
            return listaHasgtag;
        }
        return null;
    }

    public static List<String> getHashtagsByStatus(Status status) {
        List<String> hashtags = null;

        if(status!=null){
            hashtags = new ArrayList<String>();
            String tweet = status.getText();
            String[] palavras = tweet.split(" ");
            for (int i = 0; i < palavras.length; i++) {
                String string = palavras[i];
                if(isHashtag(string)){
                    if(!hashtags.contains(string))
                        hashtags.add(string);
                }
            }
            return hashtags;
        }
        return null;
    }


    public static boolean isHashtag(String palavra) {
        if(palavra.startsWith("#"))
            return true;
        return false;
    }

    public static void test() {
        try {
            List<Status> list = TwitterManager.twitter.getUserTimeline();
            for (Status status : list) {
                System.out.println(status.getUser().getScreenName());
                System.out.println(status.getText());
                System.out.println("############################################");
            }
        } catch (TwitterException ex) {
            //Logger.getLogger(TwitterManager.class.getName()).log(Level.SEVERE, null, ex);
            ex.printStackTrace();
        }
    }

    /*public static void main(String[] args) {
        TwitterManager manager = TwitterManager.getInstance();
        manager.test();
    }*/
}
