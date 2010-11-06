/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package service;

import java.util.ArrayList;
import java.util.List;
import manager.TwitterManager;
import twitter4j.Status;
import twitter4j.User;

/**
 *
 * @author wllyssys
 */
public class FriendsService {

    private TwitterManager manager = TwitterManager.getInstance();

    public FriendsService() {
        this.manager = TwitterManager.getInstance();
    }

    @SuppressWarnings("static-access")
    public List<User> getAmigos() {
        return (List<User>) manager.getAllUserFriends();
    }

    public List<Status> getTimelineDeAmigos() {
        return manager.getUserFriendsTimeline();
    }

//    public List<User> getListaDeAmigosAtiva() {
//        return null;
//    }


    public List<Status> getTimelineDeAmigosFiltrada(String listadeamigos) {
        System.out.println("FriendsService::getTimelineDeAmigosFiltrada start");
        String[] amigosArray = null;
        List<Status> timelineAmigosAtual = manager.getUserFriendsTimeline();
        List<Status> timelineAmigosFiltrada = new ArrayList<Status>();

        if(listadeamigos!=null && listadeamigos.length()>0 && timelineAmigosAtual!=null && timelineAmigosAtual.size()>0){
            amigosArray = listadeamigos.split("@");//descartarei o primeiro elemento pois ele será vazio
            System.out.println("tamanho lista filtrada chegando " + (amigosArray.length-1)  );
            for (int i = 1; i < amigosArray.length; i++) {
                String string = amigosArray[i];

                for(int j=0; j<timelineAmigosAtual.size(); j++){
                    Status status = timelineAmigosAtual.get(j);
                    if(status.getUser().getScreenName().equals(string)){
                        timelineAmigosFiltrada.add(status);
                    }
                }
            }
            System.out.println("tamanho lista filtrada pronta" + timelineAmigosFiltrada.size());
            System.out.println("FriendsService::getTimelineDeAmigosFiltrada end::usando timelineAmigosFiltrada");
            return timelineAmigosFiltrada;
        }
        System.out.println("FriendsService::getTimelineDeAmigosFiltrada end::usando timelineAmigosAtual");
        return timelineAmigosAtual;
    }

    //private boolean isUserInTimeline(Sta)

    public List<Status> getTimelineDeAmigosFiltrada_bkp(String listadeamigos) {
        System.out.println("FriendsService::getTimelineDeAmigosFiltrada start");
        String[] amigosArray = null;
        List<Status> timelineAmigosAtual = manager.getUserFriendsTimeline();
        List<Status> timelineAmigosFiltrada = new ArrayList<Status>();

        if(listadeamigos!=null && listadeamigos.length()>0 && timelineAmigosAtual!=null && timelineAmigosAtual.size()>0){
            amigosArray = listadeamigos.split("@");//descartarei o primeiro elemento pois ele será vazio
            System.out.println("tamanho lista filtrada chegando " + (amigosArray.length-1)  );
            for (int i = 1; i < amigosArray.length; i++) {
                String string = amigosArray[i];

                for(int j=0; j<timelineAmigosAtual.size(); j++){
                    Status status = timelineAmigosAtual.get(j);
                    if(status.getUser().getScreenName().equals(string)){
                        timelineAmigosFiltrada.add(status);
                    }
                }
            }
            System.out.println("tamanho lista filtrada pronta" + timelineAmigosFiltrada.size());
            System.out.println("FriendsService::getTimelineDeAmigosFiltrada end::usando timelineAmigosFiltrada");
            return timelineAmigosFiltrada;
        }
        System.out.println("FriendsService::getTimelineDeAmigosFiltrada end::usando timelineAmigosAtual");
        return timelineAmigosAtual;
    }

    public List<String> getHashtagsDaTimeline() {
        return this.manager.getHashtagsDaTimeline();
    }

    /*public static void main(String[] args) {
        FriendsService service = new FriendsService();
        List<Status> list = service.getTimelineDeAmigosFiltrada("@seumoura@CARPINEJAR@new_pedro");
        for (Status elem : list) {
            System.out.println(elem.getUser().getScreenName());
            System.out.println(elem.getText());
        }
    }*/



}
