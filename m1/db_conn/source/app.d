import std.algorithm.searching;
import std.conv;
import std.digest;
import std.digest.sha;
import std.range;
import std.stdio;
import std.string;
import std.typecons;

import vibe.db.mongo.mongo : connectMongoDB, MongoClient, MongoCollection;
import vibe.data.bson;

import dauth : makeHash, toPassword, parseHash;

struct DBConnection
{
    enum UserRet
    {
        OK,
        ERR_NULL_PASS,
        ERR_USER_EXISTS,
        ERR_INVALID_EMAIL,
        ERR_WRONG_USER,
        ERR_WRONG_PASS,
        NOT_IMPLEMENTED
    }
    MongoClient client;
    MongoCollection users, files, urls;
    this(string dbUser, string dbPassword, string dbAddr, string dbPort, string dbName)
    {
        string datab = "mongodb://"~dbUser~":"~dbPassword~"@"~dbAddr~":"~dbPort~"/";
        client = connectMongoDB(datab);
        users = client.getCollection("testing.users");
        files = client.getCollection("testing.files");
        urls = client.getCollection("testing.urls");
        
    }

    UserRet addUser(string email, string username, string password, string name = "", string desc = "")
    {
        // TODO
        if (password == null){
            return UserRet.ERR_NULL_PASS;
        } else {
            long idx_arrond = indexOf(email, '@');
            long idx_dot = indexOf(email, '.');
            long length = email.length;
            if ((idx_arrond == 0) || (idx_arrond == idx_dot - 1) || (length - idx_dot < 2) || (idx_arrond == -1)) {
                return UserRet.ERR_INVALID_EMAIL;
            } else {
                auto oneResult = users.findOne(["email": email, "username": username, "password": password]);
                if (oneResult == Bson(null)) {
                    users.insert(["email": email, "username": username, "password": password]);
                }else {
                    return UserRet.ERR_USER_EXISTS;
                }
            }
        }
        return UserRet.OK;
    }

    UserRet authUser(string email, string password)
    {
        // TODO
        long idx_arrond = indexOf(email, '@');
        long idx_dot = indexOf(email, '.');
        long length = email.length;
        if (password == null) {
            return UserRet.ERR_NULL_PASS;
        }
        if ((idx_arrond == 0) || (idx_arrond == idx_dot - 1) || (length - idx_dot < 2) || (idx_arrond == -1)) {
                return UserRet.ERR_INVALID_EMAIL;
        } else {
            auto oneResult = users.findOne(["email": email, "password": password]);
            if (oneResult == Bson(null)) {
                return UserRet.ERR_WRONG_PASS;
            }
        }
        return UserRet.OK;
    }

    UserRet deleteUser(string email)
    {
        // TODO
        long idx_arrond = indexOf(email, '@');
        long idx_dot = indexOf(email, '.');
        long length = email.length;
        if ((idx_arrond == 0) || (idx_arrond == idx_dot - 1) || (length - idx_dot < 2) || (idx_arrond == -1)) {
                return UserRet.ERR_INVALID_EMAIL;
        } else {
            users.remove(["email": email]);
        }
        return UserRet.OK;
    }

    struct File
    {
        @name("_id") BsonObjectID id; // represented as _id in the db
        string userId;
        ubyte[] binData;
        string fileName;
        string digest;
        string securityLevel;
    }

    enum FileRet
    {
        OK,
        FILE_EXISTS,
        ERR_EMPTY_FILE,
        NOT_IMPLEMENTED
    }

    FileRet addFile(string userId, immutable ubyte[] binData, string fileName)
    {
        //TODO
        if (binData == null){
            return FileRet.ERR_EMPTY_FILE;
        }
        auto oneResult = files.findOne(["userId": userId, "fileName": fileName]);
        if (oneResult != Bson(null)) {
            return FileRet.FILE_EXISTS;
        } else {
            File new_file;
            new_file.userId = userId;
            new_file.binData = cast(ubyte[])binData;
            new_file.fileName = fileName;
            new_file.digest = digest!SHA512(new_file.binData).toHexString().to!string;
            files.insert(new_file);
            return FileRet.OK;
        }
    }

    File[] getFiles(string userId)
    {
        // TODO
        File[] get_allfiles;
        File deserialized;
        auto oneResult = files.find(["userId": userId]);
        foreach(r; oneResult) {
            deserializeBson(deserialized,r);
            get_allfiles ~= deserialized;
        }
        return get_allfiles;
    }

    Nullable!File getFile(string digest)
    in(!digest.empty)
    do
    {
        // TODO
        Nullable!File file;
        auto oneResult = files.findOne(["digest": digest]);
        if (oneResult != Bson(null)) {
            deserializeBson(file,oneResult);
        }
        return file;
    }

    void deleteFile(string digest)
    in(!digest.empty)
    do
    {
        // TODO
        files.remove(["digest": digest]);
    }

    struct Url
    {
        @name("_id") BsonObjectID id; // represented as _id in the db
        string userId;
        string addr;
        string securityLevel;
        string[] aliases;
    }

    enum UrlRet
    {
        OK,
        URL_EXISTS,
        ERR_EMPTY_URL,
        NOT_IMPLEMENTED
    }

    UrlRet addUrl(string userId, string urlAddress)
    {
        // TODO
        if(urlAddress == null)
            return UrlRet.ERR_EMPTY_URL;
        Url nurl;
        nurl.userId = userId;
        nurl.addr = urlAddress;
        auto oneResult = urls.findOne(["userId": userId, "addr": urlAddress]);
        if (oneResult == Bson(null)) {
            urls.insert(nurl);
            return UrlRet.OK;
        } else {
            return UrlRet.URL_EXISTS;
        }
    }

    Url[] getUrls(string userId)
    {
        // TODO
        Url[] get_allurls;
        Url deserialized;
        auto oneResult = urls.find(["userId": userId]);
        foreach(r; oneResult) {
            deserializeBson(deserialized,r);
            get_allurls ~= deserialized;
        }
        return get_allurls;
    }

    Nullable!Url getUrl(string urlAddress)
    in(!urlAddress.empty)
    do
    {
        // TODO
        Nullable!Url url;
        auto oneResult = urls.findOne(["addr": urlAddress]);
        if (oneResult != Bson(null)) {
            deserializeBson(url,oneResult);
        }
        return url;
    }

    void deleteUrl(string urlAddress)
    in(!urlAddress.empty)
    do
    {
        // TODO
        urls.remove(["addr": urlAddress]);
    }
}
