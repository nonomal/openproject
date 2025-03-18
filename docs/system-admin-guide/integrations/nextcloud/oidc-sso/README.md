---
sidebar_navigation:
  title: Setup Single-Sign-On through OpenID Connect Identity Provider
  priority: 600
description: Set up Single-Sign-On through OpenID Connect Identity Provider as the authentication method for your Nextcloud storage
keywords: Nextcloud file storage integration
---

# Setup Single-Sign-On through OpenID Connect Identity Provider

This authentication mode will use access tokens provided by an identity provider shared among Nextcloud and OpenProject to authenticate requests performed in the name of users.

You will have to perform configuration in OpenProject, Nextcloud and in your chosen identity provider.

## 1. Prerequisites

To use SSO authentication between OpenProject and Nextcloud, a few prerequisites have to be met:

1. Users need to login to OpenProject and Nextcloud through the same identity provider
2. The identity provider needs to hand out compatible access tokens
3. The identity provider needs to allow long-term access (e.g. through the `offline_access` scope)

Those requirements are explained in more detail below.

### User authentication

The requests between OpenProject and Nextcloud usually happen on behalf of a specific user. For example when OpenProject requests a file, Nextcloud will need to make sure that the user for whom we download the file had access to it in the first place.

For that to be possible, the user must authenticate in both applications through the same identity provider.

Additionally the user account has to be created in both systems already at the time of the request. Right now this requires users to login to both systems at least once. In the future, the initial creations of accounts will also be automated.

### Token compatibility

The identity provider will need to hand out JWT encoded access tokens that can be validated according to the rules of [RFC 9068](https://www.rfc-editor.org/rfc/rfc9068). Such tokens indicate at which application they are allowed to be used (the so-called Token _Audience_) and can be validated by an application mostly without performing additional web requests to the identity provider.

It must be possible for OpenProject to obtain an access token that includes the Nexcloud client in the audience and vice versa, to allow making requests between the two applications. This has to be supported in one of two ways by the identity provider:

1. It allows to perform _OAuth 2.0 Token Exchange_ according to [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693)
2. Alternatively, it provides tokens with the necessary audience during initial SSO authentication of the user

Token exchange is generally the more secure option, since it allows fine-grained control by the identity provider which application can obtain tokens to make requests to other applications. It's usually harder to use leaked access tokens of this kind for privilege escalation. However, depending on the provider, the latter option may be easier to set-up.

### Long-term access

OpenProject relies on the ability to retain access to issued tokens over a long duration. That means issued refresh tokens should not expire under normal circumstances. This is usually achieved by requesting a scope called `offline_access` from the identity provider.

## 2. Configuring supported identity providers

The integration between OpenProject and Nextcloud has been tested with the following identity providers and we consider them officially supported:

* Keycloak
* Nextcloud Hub

Other identity providers might work as well, but we only have limited capabilities to help you in setting them up. The Keycloak instructions should explain all the general steps necessary to make it work, but the exact way to configure it for your identity provider will most likely be different.

### Keycloak

Keycloak can provide tokens via Token Exchange, as well as immediately after signing in the user. Using Token Exchange is preferred, but requires to enable two preview features in the Keycloak deployment:

* `token-exchange`
* `admin-fine-grained-authz`

If you prefer to not enable preview features on your production deployment, it's also possible to use wide-access tokens.

#### ... using Token Exchange

##### Configuring Keycloak

First make sure that you enabled both required features in Keycloak: `token-exchange` and `admin-fine-grained-authz`. You can [follow the Keycloak docs on how to do that](https://www.keycloak.org/server/features). Once they are enabled you can confirm them from the "Server Info" tab in your Keycloak installation:

![The Keycloak UI that shows enabled features](keycloak_features.png)

For the rest of this guide we will assume that you already have a client for OpenProject configured in Keycloak and it's client ID is `openproject` and a client configured for Nextcloud with the client ID `nextcloud`. We will need to allow OpenProject to exchange tokens with `nextcloud` in the audience, as well as allowing Nextcloud to exchange tokens with `openproject` in the audience.

To do this, we first create policies that will be used to control which clients are allowed to exchange tokens for a specific audience. Go to the `realm-management` client (in the default realm this client is called `master-realm`) and switch to the Tab "Authorization" and there to the "Policies" submenu. In case the "Authorization" tab is not visible, it might be necessary to make it visible by going to "Permissions" first and enabling fine-grained permissions there. Assuming you didn't create any other policies yet, your view should look similar to this:

![An empty list of policies](keycloak_empty_policies.png)

Click the "Create client policy" button and select "Client" as the policy type. Other types would be possible as well (such as Client scope), but this guide will explain the setup based on a client policy. Name the policy `allowed-to-exchange-openproject-token` and add at least `nextcloud` to the list of clients, while making sure that the Logic is "Positive". Afterwards repeat the same steps, creating a policy called `allowed-to-exchange-nextcloud-token`, including `openproject` in the list of clients:

![One of the two exchange policies configured above](keycloak_exchange_policy.png)

We will later use these policies to control who is allowed to perform a token exchange that results in a token usable for requests to the given client. For example if you have additional clients that need to obtain a token usable at OpenProject, you'd add those clients to the `allowed-to-exchange-openproject-token` client list. The names suggested here are proposals for readable policy names, but they have no practical impact.

Next we will need to use the policies, so that they actually do allow the token exchange for given clients. Navigate to the `openproject` client, go to the Tab "Permissions", enable the box "Permissions enabled" and select the permission with the name `token-exchange`. You should end up on a form similar to this one:

![Empty view of the permission configuration dialog](keycloak_exchange_permission.png)

In the field "Policies" you can now add the `allowed-to-exchange-openproject-token` we created earlier. This means that clients matching that policy will be allowed to exchange an access token that has the `openproject`.

Afterwards repeat the previous steps to add the `allowed-to-exchange-nextcloud-token` policy to the `nextcloud` client.

##### Configuring OpenProject

In OpenProject it is enough to configure the ID of the Nextcloud client (in our example: `nextcloud`) as the "Storage Audience". This will make sure that OpenProject will attempt to exchange a token for that audience before making requests to Nextcloud:

![OpenProject is configured to manually exchange tokens for the audience called nextcloud](openproject_manual_storage_audience.png)

##### Configuring Nextcloud

In Nextcloud we need to configure the OIDC provider that we are using as a common identity provider and also set the client ID of OpenProject as it's configured in Keycloak (in our case: `openproject`):

![Nextcloud is configured to exchange tokens for the audience called openproject](nextcloud_manual_storage_audience.png)

This wraps up the configuration of this authentication method using Keycloak and token exchange. For details on the next step continue with the [general setup instructions](../#4-automatically-managed-project-folders).

#### ... using wide-access tokens

##### Configuring Keycloak

We will assume that you already have a client for OpenProject configured in Keycloak and it's client ID is `openproject` and a client configured for Nextcloud with the client ID `nextcloud`. We will add client scopes that result in the inclusion of an additional audience to the tokens returned during user authentication. This will cause OpenProject to receive tokens with an additional `nextcloud` audience and Nextcloud to receive tokens with an additional `openproject` audience.

First navigate to "Client scopes" and there press the button to "Create client scope" and give the scope a name of `add-openproject-audience`. After saving your view should look similar to this:

![A newly saved client scope form](keycloak_new_client_scope.png)

This scope does not have any effect yet, we have to add a mapper first. Navigate to the "Mappers" tab, Click "Configure a new mapper" and select "Audience". Give the mapper a name of your choice and make sure to select `openproject` in "Included Client Audience". This will make sure that clients that receive a token with this scope, will get an additional audience of `openproject`:

![A configured audience mapper for including openproject as audience in a token](keycloak_audience_mapper.png)

Afterwards make sure to create another scope called `add-nextcloud-audience` that will add the `nextcloud` audience to tokens that carry it.

Finally we need to assign our newly created client scopes to our OpenProject and Nextcloud clients, so that the scopes take effect there. Navigate to the Nextcloud client, open the "Client Scopes" tab of the client and click "Add client scope". Then select the `add-openproject-audience` scope and add it as a "Default" scope:

![Nextcloud client with an additional scope added as default](keycloak_client_with_scope.png)

Adding the scope as a default scope means that it doesn't have to be explicitly requested by the client, but will be implicitly included whenever requesting a token. Lastly repeat the same steps on the OpenProject client, adding the `add-nextcloud-audience` scope.

##### Configuring OpenProject

In OpenProject configure the storage to "Use first access token obtained by identity provider". This means OpenProject will not attempt to perform a token exchange, but simply use the first token returned by the identity provider for authentication against the storage as well:

![OpenProject is configured to use the first access token obtained from the IDP](openproject_idp_storage_audience.png)

##### Configuring Nextcloud

TODO: How should we configure Nextcloud in this case? Not possible yet? Use `openproject`?

This wraps up the configuration of this authentication method using Keycloak without token exchange. For details on the next step continue with the [general setup instructions](../#4-automatically-managed-project-folders).

### Nextcloud Hub

TODO: Maybe a few introductory words about Nextcloud Hub? (e.g. "Nextcloud has two roles; 1. IDP, 2. storage)

##### Configuring OpenProject

In OpenProject configure the storage to "Use first access token obtained by identity provider". This means OpenProject will not attempt to perform a token exchange, but simply use the first token returned by the identity provider for authentication against the storage as well:

![OpenProject is configured to use the first access token obtained from the IDP](openproject_idp_storage_audience.png)

##### Configuring Nextcloud

TODO: How do we configure this scenario?

This wraps up the configuration of this authentication method using Nextcloud Hub. For details on the next step continue with the [general setup instructions](../#4-automatically-managed-project-folders).

## 3. Migrating from Two-way OAuth 2.0 authentication

It is possible to migrate an existing storage to use SSO authentication. You can follow the steps outlined above for your specific setup, all of the relevant options
in OpenProject and Nextcloud are also accessible from the views to edit your storage.

Please note that all the [prerequisites](#1-prerequisites) mentioned above still apply, this means if your users don't already authenticate to OpenProject and Nextcloud through the same
identity provider, you will have to migrate them to a common identity provider first.

If you want to go back to Two-way OAuth 2.0 authentication, this is possible as well, but will require you to reconfigure the integration, so your users will have to
reapprove the corresponding consent screens.
