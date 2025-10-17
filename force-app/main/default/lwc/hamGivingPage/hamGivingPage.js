import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';

const STRIPE_JS = 'https://js.stripe.com/v3/';

export default class HamGivingPage extends LightningElement {
    selectionPage = true;
    cartPage = false;
    paymentPage = false;

    @track
    designations = [
        {
            name: 'Innovation Center',
            id: '01t0Y0000000000000',
            selected: false,
            amount: 0,
        },
        {
            name: 'General Athletic Facilities',
            id: '01t0Y0000000000001',
            selected: false,
            amount: 0,
        },
        {
            name: 'Plant - Equipment - GIK',
            id: '01t0Y0000000000002',
            selected: false,
            amount: 0,
        },
        {
            name: 'The Sage Rink Renovation Project',
            id: '01t0Y0000000000003',
            selected: false,
            amount: 0,
        },
        {
            name: 'Unrestricted Gifts for General Purposes',
            id: '01t0Y0000000000004',
            selected: false,
            amount: 0,
        },
        {
            name: 'Innovation Center 2',
            id: '01t0Y0000000000005',
            selected: false,
            amount: 0,
        }
    ]

    frequency = 'One Time';

    publishableKey = 'pk_test_51SBP8rRkRkhJXhnsX6jzzcOvsUkzWHcJr0GnVs029jJ7HMdkdQerxYPjht6oqziknWKNmB5jqmjOYYywX1Kd4SiD00APzoFtAA';
    stripe;
    elements;
    card;
    paymentElem;
    stripeLoaded = false;
    clientSecret;

    renderedCallback() {
        if (!this.stripeLoaded && this.template.querySelector('.stripe-payment-container')) {
            console.log('Loading Stripe JS');
            this.initializeStripe();
        } 

    }

    initializeStripe() {
        const script = document.createElement('script');
        script.src = STRIPE_JS;
        script.onload = () => {
            this.stripeLoaded = true;
            this.stripe = Stripe(this.publishableKey); // Replace with your actual publishable key
            this.elements = this.stripe.elements(
                // { appearance: { theme: 'stripe' } }
                { appearance: { theme: 'stripe' }, 
                    mode: 'payment', currency: 'usd', amount: 1099 }
            );

            this.paymentElem = this.elements.create('payment', 
                {
                    layout: {
                        type: 'accordion',
                        // radios: true
                    },
                //     visibleAccordionItemsCount: 3

                //     // paymentMethodOrder: ['apple_pay', 'google_pay', 'card', 'klarna']
                }
            );

            this.paymentElem.mount(this.template.querySelector('.stripe-payment-container'));
        };

        document.head.appendChild(script); 
    }

    async handleSubmitPayment() {
        const { error } = await this.stripe.confirmPayment({
            elements: this.elements,
            confirmParams: {
                return_url: 'YOUR_RETURN_URL', // URL to redirect after payment confirmation
            },
        });

        if (error) {
            console.error('Payment error:', error.message);
            // Display error to the user
        } else {
            // Payment successful, handle accordingly
            console.log('Payment successful!');
        }
    }

    handleDonate(event){
        this.designations.forEach(designation => {
            if(designation.id === event.target.dataset.id){
                designation.selected = true;
            }
        });
    }

    handleRemoveFromCart(event){
        this.designations.forEach(designation => {
            if(designation.id === event.target.dataset.id){
                designation.selected = false;
            }
        });
    }

    handleCartClick(event) {
        if (this.cartItemsCount === 0) {
            return;
        }

        this.selectionPage = false;
        this.cartPage = true;
        this.paymentPage = false;
    }

    handleBackToSelectClick(event) {
        this.selectionPage = true;
        this.cartPage = false;
        this.paymentPage = false;
    }

    hanleProceedToPaymentClick(event) {
        this.selectionPage = false;
        this.cartPage = false;
        this.paymentPage = true;

        // TODO: fetch payment intent
        // this.stripe.createPaymentIntent({
        //     amount: 1000, // Amount in cents
        //     currency: 'usd',
        //     payment_method_types: ['card'],
        // }).then((paymentIntent) => {
            // Use the paymentIntent to create a Payment Element
            // this.stripeElements = this.stripe.elements();
            // this.elements = this.stripeElements.create('payment', {
            //     paymentIntent:
                    // console.log(paymentIntent.client_secret);
                    
                    // this.clientSecret = paymentIntent.client_secret;//,
            //         appearance: {
            //             theme: 'stripe',
            //         },
            // });
            // this.elements.mount('#payment-element');
        // });
    }

    handleSubmit(event) {
    }

    handleAmountChange(event) {
        const amount = event.target.value;
        this.designations.forEach(designation => {
            if(designation.id === event.target.dataset.id){
                designation.amount = amount;
            }
        })
    }

    handleFrequencyChange(event) {
        this.frequency = event.detail.value;
    }

    get cartItemsCount(){
        return this.designations.filter(designation => designation.selected === true).length;
    }

    get cartItems() {
        return this.designations.filter(designation => designation.selected === true);
    }

    get affiliationsOptions() {
        return [
            { label: 'Alumnus/Alumna', value: 'Alumnus/Alumna' },
            { label: 'Parent/Grandparent', value: 'Parent/Grandparent' },
            { label: 'Current Student', value: 'Current Student' },
            { label: 'Employee', value: 'Employee' },
            { label: 'Friend', value: 'Friend' },
            { label: 'Spouse', value: 'Spouse' },
        ]
    }

    get recurringOptions() {
        return [
            { label: 'One Time', value: 'One Time' },
            { label: 'Monthly', value: 'Monthly' },
            { label: 'Quarterly', value: 'Quarterly' },
            { label: 'Yearly', value: 'Yearly' },
            { label: 'Every', value: 'Every' },
        ]
    }

    get isFrequencyCustom() {
        return this.frequency === 'Every';
    }
}