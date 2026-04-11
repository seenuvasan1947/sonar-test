// BUG: any type usage, no null checks, unused variables

interface User {
    id: number;
    name: string;
    email: string;
}

// BUG: Function returns any type
function fetchUser(id: any): any {
    // BUG: No type validation
    const userData = {
        id: id,
        name: "Test User",
        email: "test@example.com"
    };
    
    return userData;
}

// BUG: Unused variable
const UNUSED_CONSTANT = "never used";

// BUG: Function with cognitive complexity
function processUsers(users: User[], filterActive: boolean, filterVerified: boolean, sortBy: string) {
    let result = users;
    
    if (filterActive) {
        if (filterVerified) {
            if (sortBy === "name") {
                result = users.filter(u => u.name).sort((a, b) => a.name.localeCompare(b.name));
            } else if (sortBy === "email") {
                result = users.filter(u => u.email).sort((a, b) => a.email.localeCompare(b.email));
            } else {
                result = users;
            }
        } else {
            result = users;
        }
    } else {
        result = users;
    }
    
    return result;
}

// BUG: Comparing with == instead of ===
function isActive(status: string): boolean {
    if (status == "active") {
        return true;
    }
    return false;
}

// BUG: Empty interface
interface EmptyConfig {}

// BUG: Class with only one method
class UserHelper {
    static formatName(user: User): string {
        return user.name.toUpperCase();
    }
}

export { fetchUser, processUsers, isActive, UserHelper };
