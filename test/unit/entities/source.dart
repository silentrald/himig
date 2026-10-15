import "package:flutter_test/flutter_test.dart";
import "package:himig/backend/entities/source.dart";
import "package:himig/backend/errors/multi_project_error.dart";
import "package:himig/backend/errors/project_error.dart";
import "package:himig/locales/enums.dart";
import "package:himig/utils/result.dart";

void main() {
  group("[Entity - Source]", () {
    group("Folder Source", () {
      void expectFolderSource(
        FolderSource folder, {
        int id = 0,
        String? name,
        String? path,
        bool? writeable,
      }) {
        expect(folder.id, id);
        expect(folder.name, name);
        expect(folder.path, path);
        expect(folder.writeable, writeable);
      }

      test("Valid source creation", () {
        final name = "Folder Source";
        final path = "/some/path/in/device";
        final writeable = true;
        final folderResult = FolderSource.create(
          name: name,
          path: path,
          writeable: writeable,
        );

        expect(folderResult, isA<ResultOk>());

        final folder = folderResult.value;
        expectFolderSource(
          folder,
          name: name,
          path: path,
          writeable: writeable,
        );
      });

      test("Deserialize source", () {
        final id = 1;
        final path = "/some/path";
        final writeable = true;
        final name = "Repo Source";

        final folder = FolderSource.fromRepo(
          id: id,
          name: name,
          data: {"path": path, "writeable": writeable},
        );

        expectFolderSource(
          folder,
          id: id,
          name: name,
          path: path,
          writeable: writeable,
        );
      });
    });

    group("Invalid Folder Source", () {
      void testInvalidFolderSource({
        String name = "",
        String path = "",
        bool writeable = true,
        required List<ProjectError> errors,
      }) {
        final result = FolderSource.create(
          name: name,
          path: path,
          writeable: writeable,
        );

        expect(result, isA<ResultError>());
        expect(result.error, isA<MultiProjectError>());
        expect((result.error as MultiProjectError).errors, containsAll(errors));
      }

      test(
        "Empty name in creation",
        () => testInvalidFolderSource(
          path: "some/path",
          errors: [
            ProjectError(ErrorLocaleKey.entitySource, "folderNameRequired"),
          ],
        ),
      );

      test(
        "Empty path in creation",
        () => testInvalidFolderSource(
          name: "Some folder name",
          errors: [
            ProjectError(ErrorLocaleKey.entitySource, "folderPathRequired"),
          ],
        ),
      );

      test(
        "All invalid fields in creation",
        () => testInvalidFolderSource(
          errors: [
            ProjectError(ErrorLocaleKey.entitySource, "folderNameRequired"),
            ProjectError(ErrorLocaleKey.entitySource, "folderPathRequired"),
          ],
        ),
      );
    });

    group("Subsonic Source", () {
      void expectSubsonicSource(
        SubsonicSource subsonic, {
        int? id = 0,
        String? name,
        bool? https,
        String? host,
        String? username,
        int? localSourceId,
      }) {
        expect(subsonic.id, id);
        expect(subsonic.name, name);
        expect(subsonic.https, https);
        expect(subsonic.host, host);
        expect(subsonic.username, username);
        expect(subsonic.localSourceId, localSourceId);
      }

      void testValidSubsonicSource({
        required String name,
        required bool https,
        required String host,
        required String username,
        required String password,
        int? localSourceId,
      }) {
        final protocol = https ? "https" : "http";
        final address = "$protocol://$host";
        final subsonicResult = SubsonicSource.create(
          name: name,
          address: address,
          username: username,
          password: password,
        );
        expect(subsonicResult, isA<ResultOk>());
        expectSubsonicSource(
          subsonicResult.value,
          name: name,
          https: https,
          host: host,
          username: username,
          localSourceId: localSourceId,
        );
      }

      test(
        "Valid https source creation",
        () => testValidSubsonicSource(
          name: "SubsonicSource",
          https: true,
          host: "some-subsonic-address",
          username: "username",
          password: "password",
        ),
      );

      test(
        "Valid http source creation",
        () => testValidSubsonicSource(
          name: "SubsonicSource",
          https: false,
          host: "127.0.0.1:5000",
          username: "username",
          password: "password",
        ),
      );

      test(
        "Valid https source creation with localSourceId",
        () =>
            () => testValidSubsonicSource(
              name: "SubsonicSource",
              https: true,
              host: "some-subsonic-address",
              username: "username",
              password: "password",
              localSourceId: 1,
            ),
      );

      test(
        "Valid http source creation with localSourceId",
        () =>
            () => testValidSubsonicSource(
              name: "SubsonicSource",
              https: false,
              host: "127.0.0.1:5000",
              username: "username",
              password: "password",
              localSourceId: 2,
            ),
      );

      test("Deserialize source", () {
        final id = 1;
        final name = "Subsonic source";
        final https = true;
        final host = "hello.com";
        final username = "username";
        final hashedPassword = "password";
        final salt = "some-salt-in-my-password";
        final localSourceId = 2;
        final subsonic = SubsonicSource.fromRepo(
          id: id,
          name: name,
          json: {
            "https": https,
            "host": host,
            "username": username,
            "password": hashedPassword,
            "salt": salt,
            "localSourceId": localSourceId,
          },
        );

        expectSubsonicSource(
          subsonic,
          id: id,
          name: name,
          https: https,
          host: host,
          username: username,
          localSourceId: localSourceId,
        );
      });
    });

    group("Invalid Subsonic Source", () {
      void testInvalidSubsonicSource({
        String name = "",
        String address = "",
        String username = "",
        String password = "",
        int? localSourceId,
        required List<ProjectError> errors,
      }) {
        final result = SubsonicSource.create(
          name: name,
          address: address,
          username: username,
          password: password,
          localSourceId: localSourceId,
        );

        expect(result, isA<ResultError>());
        expect(result.error, isA<MultiProjectError>());
        expect((result.error as MultiProjectError).errors, containsAll(errors));
      }

      test(
        "All empty",
        () => testInvalidSubsonicSource(
          errors: [
            ProjectError(.entitySource, "subsonicNameRequired"),
            ProjectError(.entitySource, "subsonicUsernameRequired"),
            ProjectError(.entitySource, "subsonicPasswordRequired"),
            ProjectError(.entitySource, "subsonicAddressRequired"),
          ],
        ),
      );

      test(
        "Invalid address",
        () => testInvalidSubsonicSource(
          name: "some name",
          address: "url://some-incorrect-address",
          username: "username",
          password: "password",
          errors: [ProjectError(.entitySource, "addressProtocol")],
        ),
      );
    });
  });
}
