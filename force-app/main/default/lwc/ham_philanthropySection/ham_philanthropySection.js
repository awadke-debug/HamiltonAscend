import { LightningElement, track, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import MY_IMPACT_CHANNEL from '@salesforce/messageChannel/myImpactChannel__c';

/**
 * @description A component to display an overview of a user's philanthropy highlights.
 * It uses Lightning Message Service to communicate with other components and handles button clicks to trigger actions.
 */
export default class Ham_philanthropySection extends LightningElement {
    @api hcBadges = [];
    @api philanthropySections = [];
    @api label = {};
    @api mainResource;
    @track images = {};

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It initializes the image paths.
     */
    connectedCallback() {
        this.images = {
            makeaGiftImage: this.mainResource + '/gift-outline.png'
        };
    }

    /**
     * @description Wire service to inject the Lightning Message Service context.
     * This context is required to publish messages to a channel.
     */
    @wire(MessageContext)
    messageContext;

     /**
     * @description Handles the click event for the "Deeper Dive" button.
     * It publishes a message to a channel to signal a state change in another component.
     * It also dispatches a custom event to the parent to trigger a scrolling action.
     */
    handleButtonClick() {
        // Create the message payload
        const payload = {
            CalledFrom: 'Deeper Dive' 
        };

        // Publish the message to the message channel
        publish(this.messageContext, MY_IMPACT_CHANNEL, payload);

        this.dispatchEvent(
            new CustomEvent('scrolltophilanthropy', {
                bubbles: false, // Let it bubble up to parent
                composed: false // Allow crossing Shadow DOM boundary
            })
        );
    }
}