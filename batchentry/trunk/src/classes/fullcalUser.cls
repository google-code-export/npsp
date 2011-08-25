public with sharing class fullcalUser {
     
    public String recentGroup { get { return pref.recentGroup; }}
    public String recentView { get { return pref.recentView; }}
    public CollaborationGroup selectedGroup { get; private set;}    
	public Event editEvent { get; set; } { editEvent = new Event(); }
	    
    public fullcalUser() { 
        // if the default group is set, fetch the group name as well
        try {
            if ( recentGroup != null ) {
                selectedGroup = [select id,name from CollaborationGroup where id = :recentGroup limit 1];       
            }
        } catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
 
	string qstr(string s) { 
		String ret = Apexpages.currentPage().getParameters().get(s) ;
		if (ret != null ) 
			ret = String.escapeSingleQuotes( ret );
		return ret; 
	}
	 
// data loading
    public List<fullcalendarEvent> allEvents { set;  
        get {
            if ( allEvents == null ) {
                allEvents = new List<fullcalendarevent>();
                String obj = qstr('groupId'); 
                String idsParam = qstr('id'); 
                
              //  system.debug(LoggingLevel.INFO,obj);
              //  system.debug(LoggingLevel.INFO,idsParam);
				
				// if id is a list of IDS, allow that
                List<string> ids = new List<string>();
                
                if ( obj != null) {
	                for (   CollaborationGroupMember member : [ select MemberId 
	                                                            from CollaborationGroupMember 
	                                                            where   collaborationGroupId=:obj limit 15])        {
	                    ids.add(member.memberid);
	                }
                } else if ( idsParam != null ) {
                    ids = idsParam.split(',');
                } 
                /*else { 
                	System.assert(false,'missing parameter to fullcaluser');
                }*/
                
                
                String st =qstr('start'); 
                if ( st != null ) 
                    startDate = Datetime.newInstance( Long.valueof( st )*1000 );  
                    
                string en =     qstr('end');
                if ( en != null ) 
                    endDate = Datetime.newInstance( Long.valueof( en )*1000 );

                // get a class name for each user
                Map<id,User> classNames = new Map<id,User>([select id, Calendar_Color__c from User where id in :ids]);// LIMIT ?
                
                
                try {
                    for( Event e: [Select e.Subject, e.StartDateTime, e.Id, e.OwnerId, e.Location, 
                                    e.IsRecurrence, e.IsPrivate, e.IsGroupEvent, e.Owner.Name,
                                    e.IsChild, e.IsArchived, e.IsAllDayEvent,  e.GroupEventType, 
                                    e.EndDateTime, e.DurationInMinutes, e.Description, e.who.name, e.what.name,
                                    e.ActivityDateTime, e.ActivityDate,e.Type
                        From Event e
                        where e.ownerid in :ids
                        AND  (e.activitydatetime >= :startDate or (e.IsAllDayEvent = true AND e.activitydate >=:startDate.date() ))
                        and   e.endDateTime <= :endDate 
                        and e.isRecurrence = false
                    //    order by e.activitydatetime
                        ]) {
                            //system.debug(LoggingLevel.INFO,e.isChild);  system.debug(LoggingLevel.INFO,e.IsRecurrence);
                            
                            // to add fields to an event, you must edit fullcalUserData page, 
                            // fullcalendarEvent class, and this list
                            fullcalendarEvent v = new fullcalendarEvent();
                            v.id = e.id;
                            v.title= e.subject;
                            v.description = e.Description;
                            v.url = '/'+e.id;
                            v.whoName = e.who.name!=null?e.who.name:'';
                            // this colors the events by who the owner is 
                            // note: the selector must start with alpha, prepend this
                            v.classname = 'fc-'+e.ownerid; //getClassName( classNames.get(e.OwnerId) );
                            
                            // this colors the events by the type they are   
                            //if (  e.Type != null ) 
                            //	v.classname = e.Type.toLowerCase();
                            
                            v.ownerid = e.OwnerId;
                            v.ownername = e.Owner.Name;
                            v.eventType = e.Type;
                         
                         	if ( e.IsAllDayEvent ) {
                             	v.allDayDate = e.activityDate;
	                            v.endDateTime = e.EndDateTime;
                                v.allDayEvent = e.IsAllDayEvent;    
                            } else {
                            	v.startDateTime = e.activityDatetime;
	                            v.endDateTime = e.endDateTime;
	                        }
	                        
	                        if ( e.Type == 'Available' ) {
	                        	v.visible = false;
	                        	v.editable = false;
	                        }
	                        allEvents.add( v);
	                        
                        }
                    
                    
                } catch (Exception e) {
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                }
            }
            return allEvents;
        }
    }   
 
 
// called from searchGroup type-ahead support
    public List<CollaborationGroup> allGroups { get{
		if ( allGroups == null ) {
			String term = qstr('term');
	        term = '%'+term.trim()+'%';
	        allGroups = [select Id,
	                Name,
	                CollaborationType,
	                Description
	                from CollaborationGroup 
	                where name like :term
	      	 	    limit 20];
		}
		return allGroups;
    } private set; }
    
    public List<Contact> allWhos { get{
		if ( allWhos == null ) {
			String term = qstr('term');
	        term = '%'+term.trim()+'%';
	        allWhos = [select Id,
	                Name
	                from Contact 
	                where name like :term
	      	 	    limit 50];
		}
		return allWhos;
    } private set; }

// interactions on the page
    public void insertNewEvent() {
        try {
            string title = qstr('title');
           
            String st =qstr('start'); 
            if ( st != null ) 
                startDate = Datetime.newInstance( long.valueof(st) );
                
            string en =     qstr('end');
            if ( en != null ) 
                endDate = Datetime.newInstance(  long.valueof(en) );
    
            string allday = qstr('allDay');
            
        //    system.debug(LoggingLevel.INFO, 'all day '+allday );
         //   system.debug(LoggingLevel.INFO, startDate.format() );                
      	//	system.debug(LoggingLevel.INFO, endDate.format() );                
            
            Long duration = (endDate.getTime() - startDate.getTime()) / 60000 ;
            
            Event event = new Event( subject=title );
            if ( allday == 'true' )  { 
                event.isAllDayEvent = true;
                event.ActivityDate = startDate.date();
            } else { 
                event.isAllDayEvent = false; 
                event.ActivityDateTime = startDate; 
                event.DurationInMinutes = duration.intValue();
            }
            
            string ownerId = qstr('ownerId');
            if ( ownerId != null && ownerId != '') {
            	event.ownerId = ownerId;
            }
            string whoId = qstr('whoId');
            if ( whoId != null && whoId != '') {
            	event.whoid = whoId;
            }

            insert event;
            
         //   system.debug(LoggingLevel.INFO,event);
            
            chatterAboutEvent( new Event[] {event} );
             
        }  catch (Exception e) {
        //	system.debug(LoggingLevel.INFO,e);
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
    
    void chatterAboutEvent(Event[] events) {
    	Event event = events[0]; 
        event = [ select id,subject,activitydatetime,owner.name,DurationInMinutes from event where id = :event.id limit 1];
        FeedPost fpost = new FeedPost();
        fpost.ParentId = selectedGroup.id; //eg. Opportunity id, custom object id..
        fpost.Body = ' scheduled a new event : '+ event.subject + ' for ' + 
        				event.owner.name + ' \n'+ 
        				' at '+ event.ActivityDateTime +  // TODO format this better
        			 	' for ' + event.DurationInMinutes + ' minutes.';
      	fpost.LinkUrl = '/'+event.id;
      	fpost.title = event.subject;

    	try { 
    		// chatter about this new event to the current group 
	        insert fpost;
    		
    	}  catch (Exception e) {
		//	system.debug(LoggingLevel.INFO,e); // can hit this if user is not in the group
			// post to the user instead
			fpost.ParentId = event.OwnerId;
			insert fpost;
        }
    } 
    
	public void saveEvent() {
		// TODO 
		
	}
	
	public void deleteEventById() {
        Id eventId = qstr('eventId');
		try {
			Event eventToUpdate = [select Id from Event where Id = :eventId limit 1];
			delete eventToUpdate;
    	}
        catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
	}
 
	public void changeEventOwner() {
        Id eventId = qstr('eventId');
        Id newOwner = qstr('ownerId');
		try {
			Event eventToUpdate = [select Id, ownerId from Event   where Id = :eventId limit 1];
			eventToUpdate.ownerId = newOwner;
			update eventToUpdate;
    	}
        catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    	 
    }        
    
    public void updateEventMove() {
        Id eventId = qstr('eventId');
        String dayDelta = qstr('dayDelta');
        String minuteDelta = qstr('minuteDelta');
 
        //system.debug(LoggingLevel.INFO, 'all day '+eventId ); system.debug(LoggingLevel.INFO, dayDelta ); system.debug(LoggingLevel.INFO, minuteDelta );                
    
        try {
            Event eventToUpdate = [select Id, activityDateTime,activityDate ,IsAllDayEvent 
            						from Event   where Id = :eventId limit 1];
            
            if ( eventToUpdate.IsAllDayEvent ) {								// day event
	       //     system.debug(LoggingLevel.INFO, eventToUpdate.activityDate);
           // 	system.debug(LoggingLevel.INFO, eventToUpdate.IsAllDayEvent);
	            if (dayDelta != '0' && dayDelta != '') {
	                Integer days = Double.valueOf(dayDelta).intValue();
	            	eventToUpdate.activityDate = eventToUpdate.activityDate.addDays(days);
	            }
            } else { 															// time event  
            //	system.debug(LoggingLevel.INFO, eventToUpdate.activityDateTime);
            
	            if(minuteDelta != '0' && minuteDelta != '' ){
	                Integer minutes = Double.valueOf(minuteDelta).intValue();
	                eventToUpdate.activityDateTime = eventToUpdate.activityDateTime.addMinutes(minutes);
	            }
		 		if (dayDelta != '0' && dayDelta != '') {
	                Integer days = Double.valueOf(dayDelta).intValue();
		          	eventToUpdate.activityDateTime = eventToUpdate.activityDateTime.addDays(days);
	            }
            }
               
            update eventToUpdate;
        }
        catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
       

    }

    public void viewDisplay() {
        
       // system.debug(LoggingLevel.INFO,'view display '+ qstr('view') );
        pref.saveView( qstr('view') );
    }    
    
    /* change the group that we are looking at, and clear the users list
     * the users is rebuilt on the next getUsers();
     */
    public void selectedGroup() {
        Id param1 = qstr('groupId');
 
        // save their most recent selection in a settings object
        ApexPages.currentPage().getParameters().put('prefspec',param1);
        pref.savePrefs();
        try { 
        	selectedGroup = [select id,name from CollaborationGroup where id = :param1 limit 1];
        }
        catch (Exception e) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        Users.clear();         
    }
    
    // inner class to add a classname
    public class UserClass { 
    	public User u {get; set; } 
    	public string classname {get; set; } 
    	public string backgroundcolor { get; set; } 
    	public string color { get; set; } 
    }
    
    public List<UserClass> Users { get {
        if ( Users.size() > 0 ) { return Users; }
        
        // from the group, list all the users
        Users.clear();
        List<Id> tmp = new List<Id>();
        if ( selectedGroup != null ) {
            for (   CollaborationGroupMember member : [ select MemberId 
                                                        from CollaborationGroupMember 
                                                        where   collaborationGroupId=:selectedGroup.id limit 15])           {
                tmp.add(member.memberid);           
            }
            
            for ( User u :  [select id,name,title,CurrentStatus, SmallPhotoUrl,Calendar_Color__c 
            					from User where id IN :tmp] ) {
                UserClass uc = new UserClass(); 
                uc.u = u;
                uc.backgroundcolor = '#3366CC';
                uc.color = '#fff';
                Chatter_Calendar_Prefs__c s = getBackgroundColor( u);
                if ( s!=null ) {
                	uc.backgroundcolor = s.background_color__c;
                	uc.color = s.color__c;
                }
                uc.classname = 'fc-'+u.id;  
                Users.add( uc );
            }
        }
        // sort the default to the top 
        List<UserClass> sorted = new List<UserClass>();
        string id =     		ChatterCalPrefs.getSettings( UserInfo.getUserId() ).Create_New_User__c;
        Integer i =0;
        while(  i< Users.size() ) {
        	//UserClass tt = Users.get(i);
        	if ( Users.get(i).u.id == id ) {
        		break;
        	}
        	i++;
        } 
        if ( i < Users.size() ) {
        	sorted.add(Users.get(i));
        	Users.remove(i);
        	sorted.addAll( Users );
        	Users = sorted;
        }
        
        
        return Users;
        } 
        private set; 
    } { Users= new List<UserClass>(); }

    
    public void updateEventResize() {
        Id eventId = qstr('eventId');
        String minuteDelta = qstr('minuteDelta');

        //system.debug(LoggingLevel.INFO, eventId ); system.debug(LoggingLevel.INFO, dayDelta );  system.debug(LoggingLevel.INFO, minuteDelta );
        
        try {
            Event eventToUpdate = [select Id, EndDateTime from Event   where Id = :eventId limit 1];
            
            if(minuteDelta != '0' && minuteDelta != '' ){
                Integer minutes = Double.valueOf(minuteDelta).intValue();
                eventToUpdate.EndDateTime = eventToUpdate.EndDateTime.addMinutes(minutes);
            }
            
            update eventToUpdate;
            //system.debug(LoggingLevel.INFO, eventToUpdate );
        }
        catch (Exception e) {
            //system.debug(LoggingLevel.INFO, e );
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
    }
    
    private Chatter_Calendar_Prefs__c getBackgroundColor( User  u ) { 
    	Chatter_Calendar_Prefs__c setting = ChatterCalPrefs.getSettings( u.id );
    	return setting;
    }
    
   	//private string getClassName(User u) {return  u.Calendar_Color__c != null ? u.Calendar_Color__c : 'gray';   	}
    private ChatterCalPrefs pref = new ChatterCalPrefs();
    private Datetime startDate { get; set; } { startDate = system.now().addMonths(-1); }
    private Datetime endDate { get; set; }   { endDate = system.now(); }
    

	public void saveColor() { 
		try {
        	String uid = qstr('userid'); 
        	
    		Chatter_Calendar_Prefs__c setting = ChatterCalPrefs.getSettings( uid );
            setting.color__c = qstr('color');
            setting.background_color__c = qstr('background');
            Database.upsert(setting);
            
        } catch (system.exception e) {
            ApexPages.addMessages(e);
        }	
	}
	
	// getDefaultOwner, setDefaultOwner
	
	public void saveNewDefaultOwner() {
		try {
        	Chatter_Calendar_Prefs__c setting = ChatterCalPrefs.getSettings( UserInfo.getUserId() ); 
    		setting.Create_New_User__c = qstr('ownerId');
            Database.upsert(setting);
            
        } catch (system.exception e) {
            ApexPages.addMessages(e);
        }	
		
	}
    
    /* 
     * building test methods here 
     */
    public static testmethod void t1() { 
        Test.setCurrentPage( Page.FullCalGroup );
		// put in an event
        Event ev = new Event(activityDateTime=System.now());
        ev.DurationInMinutes = 1;
        insert ev;
        ev = [select id,ownerid, activityDateTime, durationInMinutes from event where id = :ev.id limit 1];
        
        Event evallday = new Event(activityDate=System.today());
        evallday.IsAllDayEvent = true;
        insert evallday;
        evallday = [select id,ownerid, activityDate, durationInMinutes,enddatetime from event where id = :evallday.id limit 1];
      //  system.debug(LoggingLevel.INFO, evallday);
        
        ApexPages.currentPage().getParameters().put('id',ev.OwnerId);
        ApexPages.currentPage().getParameters().put('start', 
        	string.valueof( ev.ActivityDateTime.addMinutes(-1).getTime()/1000)  );
        ApexPages.currentPage().getParameters().put('end',
        	string.valueof( ev.ActivityDateTime.addDays(ev.durationInMinutes+1).getTime()/1000) );
        	
        fullcalUser f = new fullcalUser();
        
        map<id,fullcalendarEvent> mymap = new Map<id,fullcalendarEvent>();
        for( fullcalendarEvent ff:f.allEvents ) { mymap.put(ff.id,ff); }
        System.assert( mymap.get(ev.id) != null , 'missin event ');
        System.assert( mymap.get(evallday.id) != null , 'missin event ');
        
      //  system.debug(LoggingLevel.INFO, mymap.get(ev.id));
         
        string uniquename = 'sdlkjsdlsdjflsjdfsdfwieurosdfcxcv'; 
        CollaborationGroup cg = new CollaborationGroup();
        cg.name  = uniquename;
        cg.CollaborationType = 'Public';
        insert cg;
        
        // search for that group
        ApexPages.currentPage().getParameters().put('term',uniquename);
        CollaborationGroup[] gl = f.allGroups;
      //  system.debug(LoggingLevel.INFO, gl);
        system.assert( gl[0].name == uniquename,' missin group');
                
        ApexPages.currentPage().getParameters().put('title',uniquename);
         ApexPages.currentPage().getParameters().put('start', 
        	string.valueof( ev.ActivityDateTime.addMinutes(-1).getTime()/1000)  );
        ApexPages.currentPage().getParameters().put('end',
        	string.valueof( ev.ActivityDateTime.addDays(ev.durationInMinutes+1).getTime()/1000) );
        
        f.insertNewEvent();
        	
        ApexPages.currentPage().getParameters().put('allDay','true');
        f.insertNewEvent();
        // TODO test the above events are created
        
        f.saveEvent(); // more testing 
        
        ApexPages.currentPage().getParameters().put('eventId',ev.id);
        ApexPages.currentPage().getParameters().put('ownerId',Userinfo.getUserId() );
        f.changeEventOwner();
        
        // move a normal event
        ApexPages.currentPage().getParameters().put('eventId',ev.id);
        ApexPages.currentPage().getParameters().put('dayDelta','1');
        ApexPages.currentPage().getParameters().put('minuteDelta','10');
        f.updateEventMove();
        
        // move an all day event 
        ApexPages.currentPage().getParameters().put('eventId',evallday.id);
        ApexPages.currentPage().getParameters().put('dayDelta','1');
        ApexPages.currentPage().getParameters().put('minuteDelta','0');
        f.updateEventMove();
         
     //	system.debug(LoggingLevel.INFO, f.recentView);
        ApexPages.currentPage().getParameters().put('view',f.recentView);
        f.viewDisplay();
        
        ApexPages.currentPage().getParameters().put('groupId',cg.id);
        f.selectedGroup();
        system.assert(f.selectedGroup.id == cg.id );
        List<UserClass> ul = f.Users;
        system.assert( f.Users == ul );
        
        ApexPages.currentPage().getParameters().put('ownerId','foo');
        f.saveNewDefaultOwner();       
        
        ApexPages.currentPage().getParameters().put('eventId',ev.id);
        ApexPages.currentPage().getParameters().put('minuteDelta','10');
        f.updateEventResize();
        
        Event eventToUpdate = [select Id,DurationInMinutes from Event where Id = :ev.id limit 1];
     //   system.debug(LoggingLevel.INFO, eventToUpdate );
     //   system.assert( eventToUpdate.DurationInMinutes == 11);
        
        f.deleteEventById();
 
        ApexPages.currentPage().getParameters().put('color','foo');
        ApexPages.currentPage().getParameters().put('backgroundcolor','bar');
 		
 		f.saveColor();       
        return;
               
    }   
}