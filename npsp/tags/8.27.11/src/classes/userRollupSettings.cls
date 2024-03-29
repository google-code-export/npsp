/*
    Copyright (c) 2009, Salesforce.com Foundation
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
public with sharing class userRollupSettings {
    
    //controls which types to display
    map<string, Schema.Displaytype> mapFieldTypes = new map<string, Schema.Displaytype>();
    map<string, Schema.Displaytype> targetFieldTypes = new map<string, Schema.Displaytype>();
        
    //pickers for setting values   
    public list<SelectOption> sourcefields = new list<SelectOption>();
    public list<SelectOption> validoperators = new list<SelectOption>();
    public list<SelectOption> targetfields = new list<SelectOption>();
    public list<object> mylist = new list<object>();
    public list<SelectOption> targetobjects = new list<SelectOption>{
    new SelectOption('Account', 'Account'),
    new SelectOption('Contact', 'Contact'),
    new SelectOption('Household__c', 'Household__c')    
    }; 
    
    //defines values for the final list setting
    public string operator{get; set;}    
    public string opptyfield{get; set;}
    public string targetfield{get; set;}
    public string targetobject{get; set;}
       
    //the test string of the rollup
    public string operationstring;
    
    //controls wizard steps
    public integer step{get; set;}
    
    //constructor
    public userRollupSettings(){
       step = 0;
    }    
    
    //called on load of the page
    public PageReference checkSettings(){
        //if there are invalid rollups defined, display an error 
        if (!userRollupsValid()){
            showMsg('INVALID USER SETTINGS DETECTED - Some user defined rollups have been disabled',ApexPages.Severity.ERROR);
            showMsg('User defined rollups reference target or source fields which do not exist.  Please update or delete the invalid rollups to re-enable.', ApexPages.Severity.WARNING);
        }       
        return null;
    }

    public void next(){
    	this.step++;
    }
    public void back(){
        this.step--;
    }
    
    //reset all instance variable and return to initial screen
    public void cancel(){    	
        this.sourcefields.clear();
        this.mapFieldTypes.clear();
        this.validoperators.clear();
        this.targetfields.clear();
        this.opptyfield = null;
        this.operator = null;
        this.targetfield = null;
        this.operationstring = null;
        this.step = 0;      
    }
    
    //retrieve syntax for fields
    public string getOperationString(){
        operationstring = 'Rollup the ' + this.operator + ' of the ' + this.opptyfield + ' field on opportunity and place the result in the ' + this.targetfield + ' field on ' + this.targetobject + '?';
        return operationstring;
    }
    
    //retrieve target objects
    public list<SelectOption> getTargetObjects(){
        return this.targetobjects;
    }
    //retrieve valid operators
    public list<SelectOption> getValidOperators(){
        validoperators.clear();
        if (mapFieldTypes.containsKey(opptyfield)){
           validoperators.add(new SelectOption('MIN', 'MIN'));
           validoperators.add(new SelectOption('MIN', 'MAX'));  
           
            if ((mapFieldTypes.get(opptyField) != Schema.Displaytype.Date) && (mapFieldTypes.get(opptyField) != Schema.Displaytype.Datetime)){  
                validoperators.add(new SelectOption('AVG', 'AVG'));
                validoperators.add(new SelectOption('SUM', 'SUM'));                
            }
        }    
        return validoperators; 
    }
    
    //retrieve possible target fields for the selected object
    public list<SelectOption> getTargetFields(){ 
        
        targetfields.clear();
        set<string> knownfields;    
        map<string, Schema.Sobjectfield> targetTokenMap = new map<string, Schema.Sobjectfield>();
        
        //need to load current settings to not allow the user to point to the same target field
        //twice
        map<string, User_Rollup_Field_Settings__c> currentURFSMap = User_Rollup_Field_Settings__c.getAll();
        set<string> currentTargetFieldSet = new set<string>();
        for (string s : currentURFSMap.keySet()){
        	if (currentURFSMap.get(s).Object_Name__c == targetObject){
        	   string fieldname = (currentURFSMap.get(s).Target_Field__c).toLowerCase();
        	   //we need to strip out the namespace
        	   if (fieldname.contains('npo02')){
        	   	   fieldname = fieldname.replace('', '');
        	   	
        	   }
        	   else if (fieldname.contains('npe01')){
        	   	   fieldname = fieldname.replace('', '');
        	   }
        	   currentTargetFieldSet.add(fieldname);
        	}
        }  
         
        if (targetobject == 'Contact'){
            targetTokenMap = Schema.SObjectType.Contact.fields.getMap().clone();
            knownfields = new set<string>{
                'averageamount__c', 'donor__c', 'donor_this_year__c',                
                'firstclosedate__c', 'household__c', 'formula_householdmailingaddress__c',
                'formula_householdphone__c', 'languages__c', 'largestamount__c', 
                'lastoppamount__c', 'lastclosedate__c', 'lastclosedatehh__c',
                'lastmembershipdate__c', 'lastmembershiplevel__c', 'lastmembershipamount__c',
                'lastmembershiporigin__c', 'last_donation_date__c', 'level__c',
                'membershipenddate__c', 'membershipjoindate__c', 'membership_span__c',
                'membership_status__c', 'new_donor_this_year__c', 'oppsclosedlastndays__c',
                'oppsclosedlastyear__c', 'oppsclosedthisyear__c', 'oppsclosed2yearsago__c',
                'numberofmembershipopps__c', 'smallestamount__c', 'totaloppamount__c',
                'oppamountlastndays__c', 'oppamountlastyear__c', 'oppamountthisyear__c',
                'oppamount2yearsago__c', 'total_household_gifts__c', 'oppamountlastndayshh__c',
                'oppamountlastyearhh__c', 'oppamountthisyearhh__c', 'totalmembershipoppamount__c',
                'numberofclosedopps__c', 'systemhouseholdprocessor__c', 'naming_exclusions__c'};
        }
        else if(targetobject == 'Account'){
            targetTokenMap = Schema.SobjectType.Account.fields.getMap().clone();
            knownfields = new set<string>{
                'active__c', 'averageamount__c', 'customer_priority__c', 'customerpriority__c',
                'upsellopportunity__c', 'firstclosedate__c', 'largestamount__c', 'lastoppamount__c',
                'lastclosedate__c', 'lastmembershipdate__c', 'lastmembershipamount__c',
                'lastmembershiplevel__c', 'lastmembershiporigin__c', 'membershipenddate__c',
                'membershipjoindate__c', 'membership_span__c', 'membership_status__c',
                'oppsclosedlastndays__c', 'oppsclosedlastyear__c', 'oppsclosedthisyear__c',
                'oppsclosed2yearsago__c', 'numberoflocations__c', 'numberofmembershipopps__c',
                'sla__c', 'slaexpirationdate__c', 'slaserialnumber__c', 'smallestamount__c',
                'totaloppamount__c', 'oppamountlastndays__c', 'oppamountlastyear__c', 'oppamountthisyear__c',
                'oppamount2yearsago__c', 'totalmembershipoppamount__c', 'numberofclosedopps__c'
           };
        }
        else if(targetobject == 'Household__c' || targetobject == 'Household__c'){
            targetTokenMap = Schema.SobjectType.Household__c.fields.getMap().clone();
            knownfields = new set<string>{
                'addressee__c', 'always_anonymous__c', 'averagemount__c', 'firstclosedate__c',   
                'householdemail__c','household_id__c','householdphone__c','largestamount__c',
                'lastoppamount__c','lastclosedate__c','lastmembershipamount__c','lastmembershipdate__c',       
                'lastmembershiplevel__c','lastmembershiporigin__c','formula_mailingaddress__c',    
                'mailingcity__c','mailingcountry__c','mailingstate__c','mailingstreet__c',     
                'mailingpostalcode__c','membershipenddate__c','membershipjoindate__c','membership_span__c',      
                'membership_status__c','oppsclosedlastndays__c','oppsclosedlastyear__c',       
                'oppsclosedthisyear__c','oppsclosed2yearsago__c','numberOfmembershipopps__c',   
                'smallestamount__c','totaloppamount__c','oppamountlastndays__c','oppamountlastyear__c',    
                'oppamountthisyear__c','oppamount2yearsago__c','totalmembershipoppamount__c',    
                'numberofclosedopps__c', 'formal_greeting__c', 'informal_greeting__c', 'averageamount__c',
                'system_custom_naming__c'
           };     
        }
        
        if(!currentTargetFieldSet.isEmpty())
            knownfields.addAll(currentTargetFieldSet);
        
        //pop out the known fields
        for (string s : knownfields){
        	s = s.toLowerCase();
        	targetTokenMap.remove(s);
        }
        
        if ((targettokenMap.size() < 75) && (targettokenMap.size() > 0)){
        
            for (string s : targetTokenMap.keyset()){            
                if (s.contains('__c') && (!s.startswith(''))){
                    Schema.DescribeFieldResult F = targetTokenMap.get(s).getDescribe();                  
                    targetfields.add(new SelectOption(f.getName(), s));    
                }
            }
        }
        
        if (targetfields.size() < 1){            
            targetfields.add(new SelectOption('NO VALID FIELD AVAILABLE', 'NO VALID FIELD AVAILABLE'));
            showMsg('No valid target field was found for the type of rollup defined. Please add a custom field, or select a different object and try again.', ApexPages.Severity.INFO);                
        }
        return targetfields;    
    }
    
    //retrieve valid source fields from opportunity object
    public list<SelectOption> getSourceFields(){
        
        set<string> knownOpptyFields = new set<string>{'Amount', 'CloseDate', 'ExpectedRevenue', 
        	'Probability', 'TotalOpportunityQuantity', 'membership_start_date__c', 'membership_end_date__c'};
        
        if (sourcefields.isEmpty()){
                       
            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
           
            //loop through the map, only get the describe information for fields we don't
            //already recognize, including our own and non-custom fields, we'll add those in a moment
            for(string fieldName : oppFieldTokenList.keyset()){
                if (fieldname.contains('__c') && (!knownopptyFields.contains(fieldName))){
                    Schema.DescribeFieldResult F = oppFieldTokenList.get(fieldName).getDescribe();                  
                    
                    Schema.Displaytype dt = f.getType();
                    if ((dt == Schema.Displaytype.Currency) ||
                        (dt == Schema.Displaytype.Date) ||
                        (dt == Schema.Displaytype.Datetime) ||
                        (dt == Schema.Displaytype.Double) ||
                        (dt == Schema.Displaytype.Integer) ||
                        (dt == Schema.Displaytype.Percent)){                                
                        
                        sourcefields.add(new SelectOption(f.getName(),fieldname));
                        mapFieldTypes.put(f.getName(), dt);                    
                    }
                }
           }
           //now add our known field types
           for(string knownField : knownopptyFields){
                sourcefields.add(new SelectOption(knownField, knownField));
           
                if((knownfield == 'Amount') || (knownfield == 'ExpectedRevenue'))
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Currency);         
                else if((knownfield == 'CloseDate')||(knownfield == 'membership_start_date__c') || (knownfield == 'membership_end_date__c'))                  
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Date);
                else
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Double);   
           }
        }
       
        return sourceFields;
    }

    //utility to check that existing user defined rollups are valid - called onpageload
    //NOTE: Only checks that target/source fields exist, not operation validity
    private boolean userRollupsValid(){
        boolean isValid = true;
        
        map<string, User_Rollup_Field_Settings__c> userRollups = User_Rollup_Field_Settings__c.getAll(); 
    
        for (string s : userRollups.keySet()){
            User_Rollup_Field_Settings__c urfs = userRollups.get(s);
            SobjectField targetField;
            SobjectField sourceField;
            
            //check source field
            sourceField = Schema.sObjectType.Opportunity.fields.getMap().get(urfs.Source_Field__c);
            if (sourceField == null) isValid = false;
                      
            //check target fields            
            if (urfs.Object_Name__c == 'Contact'){
                targetField = Schema.sObjectType.Contact.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;
            }
            else if (urfs.Object_Name__c == 'Account'){
                targetField = Schema.sObjectType.Account.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;               
            }
            else if (urfs.Object_Name__c == 'Household__c' || urfs.Object_Name__c == 'Household__c'){
                targetField = Schema.sObjectType.Household__c.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;
            }
            else isValid = false;
        }    
    
    return isValid;
    }           
        
    //used to render error messages on the VF interface
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }    
    
    //save and commit rollup
    public PageReference createRollup(){
    	try{
    		map<string, User_Rollup_Field_Settings__c> userRollups = User_Rollup_Field_Settings__c.getAll();
            integer nameNumber = userRollups.size();
    		 
    		User_Rollup_Field_Settings__c newURFS = new User_Rollup_Field_Settings__c(Name = 'CustomRollup' + nameNumber, 
    		Object_Name__c = targetobject, Target_Field__c = targetfield, Field_Action__c = operator,
    		Source_Field__c = opptyfield
    		);    		
    		insert newURFS;    		
    	}
    	
    	catch(Exception e){
    		 showMsg('An unhandled exception has occurred. Please try again.',ApexPages.Severity.FATAL);
    		 showMsg('Exception type' + e, ApexPages.Severity.INFO);    		 
    	}
    	
    	return ApexPages.currentPage().setRedirect(true);
    }   
        
    public static testMethod void TEST_userRollupSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.userRollupSettings'));
        
        //pass the controller into the extension
        userRollupSettings controller = new userRollupSettings();
        
        //exercise basic operations
        controller.next();
        system.assertEquals(controller.step, 1);
        controller.next();
        system.assertEquals(controller.step, 2);
        controller.back();
        system.assertEquals(controller.step, 1);
        controller.cancel();
        system.assertEquals(controller.step, 0);
        
        //check settings returns a null pagereference
        PageReference samePage = controller.checkSettings();
        system.assertEquals(samePage, null);
        
        //call the major getter methods
        list<SelectOption> oppyList = controller.getSourceFields();
        controller.opptyfield = 'Amount';
        list<SelectOption> operatorList = controller.getValidOperators();
        
        controller.opptyfield = 'CloseDate';
        operatorList = controller.getValidOperators();
        controller.operator = 'MAX';
        
        list<SelectOption> targetObjectList = controller.getTargetObjects();
        controller.targetobject = 'Account';
        list<SelectOption> targetFieldList = controller.getTargetFields();
               
        //change target object to test other options        
        controller.targetobject = 'Household__c';
        targetFieldList = controller.getTargetFields();
        
        controller.targetobject = 'Contact';
        targetFieldList = controller.getTargetFields();
        system.assertEquals(targetObjectList.size(), 3);
        
        controller.targetfield = 'Birthdate';
        
        string operationdescription = controller.getOperationString();
        controller.createRollup();
        
        //existing invalid rollups will cause test failure
        boolean isValid = controller.userRollupsValid();
        system.assertEquals(isValid, true);
        
        //insert invalid rollup to test error handling methods
        User_Rollup_Field_Settings__c badurfs = new User_Rollup_Field_Settings__c(
        Name = 'Invalid Test Rollup',
        Target_Field__c = 'InvalidTargetField__test',
        Source_Field__c = 'InvalidSourceField__test',
        Object_Name__c = 'Account',
        Field_Action__c = 'TEST'         
        );
        
        insert badurfs;
        
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
        PageReference pr = controller.checkSettings();        
        
        //exercise household code
        User_Rollup_Field_Settings__c HHurfs = new User_Rollup_Field_Settings__c(
        Name = 'Household Test Rollup',
        Target_Field__c = 'lastoppamount__c',
        Source_Field__c = 'Amount',
        Object_Name__c = 'Household__c',
        Field_Action__c = 'MAX'         
        );
        
        insert HHurfs; 
                
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
        
        //insert a bogus rollup using the createRollup() method
        controller.operator = null;
        pr = controller.createRollup();
        
        User_Rollup_Field_Settings__c badobject = new User_Rollup_Field_Settings__c(
        Name = 'Invalid Object Rollup',
        Target_Field__c = 'InvalidTargetField__test',
        Source_Field__c = 'InvalidSourceField__test',
        Object_Name__c = 'BadAccount',
        Field_Action__c = 'TEST'
        );
        
        insert badobject;
        
        isValid = controller.userRollupsValid();
        system.assertEquals(false, isValid);
        
    }
}