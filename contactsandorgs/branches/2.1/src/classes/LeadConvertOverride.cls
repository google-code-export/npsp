/*
    Copyright (c) 2010, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Jason Venable & Evan Callahan
* @date 2010 (2.x)
* @description Controller for lead conversion of 1x1 contacts
*/
public with sharing class LeadConvertOverride {
// Controller for lead conversion of one-to-one contacts
 
// Written by jason venable and evan callahan
// at the NPSP Sprint 2010    

    // properties for page
    public lead l { get; set; }
    public opportunity dummyOpp { get; set; }
    public boolean sendEmailToOwner { get; set; }
    //public string acct { get; set; }  
    public string con { get; set; }
    public string oppName { get; set; }
    public boolean doNotCreateOpp { get; set; }
    public string leadConvStatus { get; set; }
    //public task leadTask { get; set; }

    //public list<selectOption> acctList = new list<selectOption>(); 
    public list<selectOption> conList; 
    map<id, contact> conMap = new map<id, contact>(); 
    public list<selectOption> lcStatuses; 
    
    public LeadConvertOverride(ApexPages.StandardController controller) {
                
        // get the lead
        l = [select id, name, firstname, lastname, company, email, ownerId from lead
            where id = : controller.getId()];
        
        // dummy opp allows owner selection
        dummyOpp = new Opportunity( 
            ownerid = ((((string)(l.ownerid)).startsWith('005')) ? l.ownerid : userInfo.getUserId())
        );
        
        // set a default opp name
        oppName = l.name;
        doNotCreateOpp = false;
        
    }    
    
    public list<selectOption> getConList() {
        if (conList == null) { 
            conList = new list<selectOption>();
            
            conList.add( new SelectOption('', '--None--') );
            conList.add( new SelectOption('NEW_CONTACT', 'Create New: ' + l.name) );            
        
            // find contact matches
            conMap = new map<id, contact>([select id, name, accountid, firstname, lastname from contact where 
                (lastname = : l.lastname and firstname = : l.firstname) or
                (email = : l.email and email != null) limit 50]);
                
            for (contact c : conMap.values()) {
                conList.add( new SelectOption(c.id, 'Merge with Existing: ' + c.name) );                            
            }
        }
        return conList; 
    } 
    
    public list<selectOption> getlcStatuses() {
        if (lcStatuses == null) {
            lcStatuses = new list<selectOption>();
            // query
            for (LeadStatus ls : [Select Id, MasterLabel from LeadStatus where IsConverted=true] ) {
                lcStatuses.add( new SelectOption(ls.masterLabel, ls.masterLabel ));
            }
            leadConvStatus = lcStatuses[0].getValue();
        }
        return lcStatuses;
    } 
    
    public pageReference convertLead()
    {
        //String lId = ApexPages.currentPage().getParameters().get('id');  
        PageReference pageRef;
        
        //don't test if we're not in the one-to-one model
        if (Constants.isOneToOne() && !((l.company.toUpperCase() != 'INDIVIDUAL' && 
                (l.company == null || l.company == '' || l.company.toUpperCase() == 'SELF' || 
                l.company.toUpperCase() == l.name)))) {

            pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' + l.Id + '&id=' + l.Id + '&nooverride=1');
            pageRef.setRedirect(true);
        }
        return pageRef;
    }           

    public pageReference convertOneToOne() {
        if (con == null) {
            apexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.Error,
                'You must select an option in the Contact box.'
            ));
            return null;
        }
        
        // set up the conversion
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.Id);
        if (!doNotCreateOpp) lc.setOpportunityName(oppName);
        lc.setDoNotCreateOpportunity(doNotCreateOpp);
        lc.setConvertedStatus(leadConvStatus);

        // is this a merge to existing?
        if (con != 'NEW_CONTACT') { 
            // get this contact's account
            lc.setContactId(con);
            lc.setAccountId(conMap.get(con).accountId);          
        }       

        // convert the lead
        PageReference pageRef;
        Database.LeadConvertResult lcr;
        try {
            lcr = Database.convertLead(lc);
            
            
            // fix the account that lead conversion created
            if (con == 'NEW_CONTACT') {     
                //
                Contact[] myconvertedContact = [select id,firstname, lastname from contact where id=:lcr.getContactId()];
                
                Account myAccount = new Account(Id=lcr.getAccountId());
                myAccount.Name= myconvertedContact[0].firstName + ' ' + myconvertedContact[0].lastName;
                myAccount.One2OneContact__c=lcr.getContactId();
                myAccount.SYSTEM_AccountType__c = Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                myAccount.SYSTEMISINDIVIDUAL__c = true;
                update myAccount;
            }   
            
            
            
            pageRef = new PageReference('/' + lcr.getContactId());          
        } catch (exception e) {
            apexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.Error, e.getMessage())
            );
        }
        
                            
        
        // redirect
        return pageRef;     
    }
}