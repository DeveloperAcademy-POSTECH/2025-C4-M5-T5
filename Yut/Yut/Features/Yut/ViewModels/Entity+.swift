import RealityKit

extension Entity {
    // 충돌 모양을 생성하고 Collision, Physicsbody를 적용하는 함수
    func generateStaticShapeResources(
        recursive: Bool = true,
        filter: CollisionFilter = .default
    ) async throws {
        var shapes: [ShapeResource] = []
        if let meshResource = self.components[ModelComponent.self]?.mesh {
            let shape = try await ShapeResource.generateStaticMesh(from: meshResource)
            shapes.append(shape)
        }
        self.components.set([
            // collision 적용, static
            CollisionComponent(
                shapes: shapes,
                mode: .default,
                collisionOptions: .static,
                filter: filter
            ),
            // 물리바디 적용
        ])
        // 재귀적으로 하위 엔티티들까지 전부 같은 방식으로 콜리전, 물리 바디 세팅
        if recursive {
            for child in self.children {
                try await child.generateStaticShapeResources(
                    recursive: true,
                    filter: filter
                )
            }
        }
    }
}
