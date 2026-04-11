// BUG: Using eval, no error handling, implicit globals

var userName = "test"; // BUG: Using var instead of let/const

function processUserData(data) {
    // BUG: No validation on input
    var result = eval(data); // BUG: Using eval - security vulnerability
    
    if (result != null) { // BUG: Using != instead of !==
        console.log("Result: " + result);
    }
    
    // BUG: Callback not handling errors
    setTimeout(function() {
        var processed = result * 2;
        console.log("Processed: " + processed);
    }, 1000);
    
    return result;
}

// BUG: Function declared but never called
function unusedHelper() {
    var x = 10;
    var y = 20;
    return x + y;
}

// BUG: Implicit global variable
globalConfig = {
    apiUrl: "http://localhost:3000/api", // BUG: HTTP instead of HTTPS
    timeout: 5000,
    retries: 3
};

// BUG: Comparing with == instead of ===
function checkStatus(status) {
    if (status == "active") {
        return true;
    } else if (status == "inactive") {
        return false;
    }
    return null;
}

// BUG: No input validation
function calculateTotal(items) {
    var total = 0;
    for (var i = 0; i < items.length; i++) {
        total += items[i].price;
    }
    return total;
}

// BUG: Dead code
function legacyFunction() {
    console.log("This function is deprecated");
    return null;
    var afterReturn = "never reached"; // BUG: Unreachable code
}

module.exports = {
    processUserData,
    checkStatus,
    calculateTotal
};
