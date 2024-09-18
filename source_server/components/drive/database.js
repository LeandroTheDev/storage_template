//Dependencies
const Sequelize = require('sequelize');
class DriveDatabase {
    //Contains the connection with database
    database_connection;
    //Contains the users database
    accounts;

    constructor() {
        try {
            ///Creates the connection with database
            this.database_connection = new Sequelize('storage', "nas_admin", "password", {
                host: "databaseip",
                dialect: "mariadb",
                logging: false,
                sync: true,
                dialectOptions: {
                    connectTimeout: 30000
                }
            })
            ///With connection instanciate the table
            this.accounts = this.database_connection.define('accounts', {
                id: {
                    type: Sequelize.INTEGER,
                    autoIncrement: true,
                    allowNull: false,
                    primaryKey: true
                },
                username: {
                    type: "varchar(50)",
                    allowNull: false,
                    unique: true
                },
                password: {
                    type: "varchar(500)",
                    allowNull: false,
                },
                token: {
                    type: "longtext",
                    allowNull: true,
                    defaultValue: null
                }
            }, {
                //Disable defaults from sequelize
                timestamps: false,
                createdAt: false,
                updatedAt: false,
            });
            ///Creates the table if not exist
            this.database_connection.authenticate().catch(err => {
                console.log("[Drive Database] connection lost");
            });
        } catch (error) {
            console.log("[Drive Database] cannot connect to the database: " + error);
        }
    }

    /**
    * Get actual user token in database
    *
    * @param {String} username - "user"
    * @returns {Promise} "123...", null if a database error occurs
    */
    getUserToken(username) {
        return new Promise(async (resolve, _) => {
            try {
                //Getting the token
                let user = await this.accounts.findOne({
                    attributes: ['token'],
                    where: {
                        username: username,
                    }
                });
                if (user == null) {
                    resolve(null);
                    return;
                }
                //Returning the token
                resolve(user.token);
            } catch (error) {
                console.log("[Drive Database] " + username + " crashed get user token: " + error)
                resolve(null);
            }
        });
    }

    /**
    * Update the user token based in username
    *
    * @param {String} token - "123..."
    * @param {String} username - "user"
    * @returns {Promise} false no errors, true means errors
    */
    updateUserToken(token, username) {
        return new Promise(async (resolve, _) => {
            try {
                //Get the user key
                let user = await this.accounts.findOne({
                    where: {
                        username: username,
                    }
                });
                //Change the token section to null
                user.token = token;
                //Confirm changes
                user.save();

                //Finish
                console.log("[Drive Database] " + username + " token updated");
                resolve(false);
            } catch (error) {
                console.log("[Drive Database] " + username + " crashed update user token: " + error)
                resolve(true);
            }
        });
    }

    /**
    * Invalidate the user token based in username
    *
    * @param {String} username - "user"
    * @returns {Promise} - false no errors, true means errors
    */
    invalidateUserToken(username) {
        return new Promise(async (resolve, _) => {
            try {
                //Get the user key
                let user = await this.accounts.findOne({
                    attributes: ['token'],
                    where: {
                        username: username,
                    }
                });
                //Change the token section to null
                user.token = null;
                //Confirm changes
                user.save();

                //Finish
                console.log("[Drive Database]" + username + " token invalidated");
                resolve(false);
            } catch (error) {
                console.log("[Drive Database] " + username + " crashed invalidate user token: " + error)
                resolve(true);
            }
        });
    }

    /**
    * Try to login in the user
    *
    * @param {String} username - "user"
    * @param {String} password - "supersecret"
    * @returns {Promise} true for correct credentials, false for wrong credentials, null for errors
    */
    login(username, password) {
        return new Promise(async (resolve, reject) => {
            try {
                //Get the user key
                let user = await this.accounts.findOne({
                    attributes: ["password"],
                    where: {
                        username: username,
                    }
                });
                //The user doesnt exist
                if (user == null) {
                    resolve(false);
                    return;
                }
                //Check if the password is correct
                if (user.password == password) resolve(true);
                else resolve(false);
            } catch (error) {
                console.log("[Drive Database] " + username + " crashed login: " + error);
                resolve(null);
            }
        });
    }

    /**
    * Close the database connection
    */
    close() {
        this.database_connection.close();
    }
}
module.exports = new DriveDatabase;