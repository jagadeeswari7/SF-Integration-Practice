import { createElement } from 'lwc';
import HighNetWorthClient from 'c/highNetWorthClient';
import determineRecordAccess from '@salesforce/apex/HighNetWorthClientController.determineRecordAccess';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Register as an Apex wire adapter. Some other wire adapters use `registerLdsTestWireAdapter`.
const determineRecordAccessAdapter = registerApexTestWireAdapter(determineRecordAccess);

describe('c-high-net-worth-client', () => {
    afterEach(() => {
        // Clean up after each test
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders correct mode and access data when record access is granted', async () => {
        const OBJECT_API_NAME_INPUT = 'Account';
        // Create the component
        const element = createElement('c-high-net-worth-client', {
            is: HighNetWorthClient,
        });
        element.recordId = '0017F00000XXXXXX';
        element.objectApiName = OBJECT_API_NAME_INPUT;
        document.body.appendChild(element);

        // Emit data from the wire adapter
        determineRecordAccessAdapter.emit({
            hasRecordAccess: true,
            mode: 'edit',
        });

        // Wait for the wire to emit
        await Promise.resolve();

        // Validate if correct parameters have been passed to base components
        const formEl = element.shadowRoot.querySelector(
            'lightning-record-form'
        );
        expect(formEl.objectApiName).toBe(OBJECT_API_NAME_INPUT);
    });

    it('shows error toast when record access is denied', async () => {
        const element = createElement('c-high-net-worth-client', {
            is: HighNetWorthClient,
        });
        element.recordId = '0017F00000XXXXXX';
        document.body.appendChild(element);

        // Mock ShowToastEvent handler
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Emit data indicating no access
        determineRecordAccessAdapter.emit({
            hasRecordAccess: false,
        });

        // Wait for the wire to emit
        await Promise.resolve();

        // Check that an error toast is displayed
        const formEl = element.shadowRoot.querySelector(
            'lightning-record-form'
        );
        expect(formEl).toBeNull();
        const errorMessage = element.shadowRoot.querySelector('.checkRecordAccess');
        expect(errorMessage.textContent).toBe('Insufficient privileges to open the page; please contact the administrator.');
    });

    it('handles Apex wire errors gracefully and shows error toast', async () => {
        const element = createElement('c-high-net-worth-client', {
            is: HighNetWorthClient,
        });
        // Mock ShowToastEvent handler
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        document.body.appendChild(element);

        // Emit an error from the wire adapter
        determineRecordAccessAdapter.error();

        // Wait for the wire to emit
        await Promise.resolve();

        // Verify an error toast is shown
        expect(toastHandler).toHaveBeenCalled();
        const toastEvent = toastHandler.mock.calls[0][0];
        expect(toastEvent.detail.title).toBe('Error');
        expect(toastEvent.detail.message).toBe(
            'Error checking record access. Please contact your administrator.'
        );
    });

    it('shows success toast on handleSuccess', () => {
        const OBJECT_API_NAME_INPUT = 'Account';
        // Create the component
        const element = createElement('c-high-net-worth-client', {
            is: HighNetWorthClient,
        });
        element.recordId = '0017F00000XXXXXX';
        element.objectApiName = OBJECT_API_NAME_INPUT;
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Invoke handleSuccess to simulate a successful save
        const formEl = element.shadowRoot.querySelector(
            'lightning-record-form'
        );

        // Assert that a success toast was shown
        expect(toastHandler).toHaveBeenCalled();
        const toastEvent = toastHandler.mock.calls[0][0];
        expect(toastEvent.detail.title).toBe('Success');
        expect(toastEvent.detail.message).toBe('Record updated successfully');
        expect(toastEvent.detail.variant).toBe('success');
    });
});
