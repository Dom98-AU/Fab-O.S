window.clipboardFunctions = {
    copyToClipboard: function (text) {
        navigator.clipboard.writeText(text).then(function () {
            console.log('Copied to clipboard');
            return true;
        }).catch(function (error) {
            console.error('Failed to copy: ', error);
            return false;
        });
    }
};